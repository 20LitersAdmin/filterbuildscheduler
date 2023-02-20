# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Replicator, type: :model do
  let(:base_event) { create :event }
  let(:replicator) { build :replicator, start_time: base_event.start_time, end_time: base_event.end_time }

  it 'has attributes' do
    expect(Replicator.attribute_method?(:start_time)).to eq true
    expect(Replicator.attribute_method?(:end_time)).to eq true
    expect(Replicator.attribute_method?(:frequency)).to eq true
    expect(Replicator.attribute_method?(:interval)).to eq true
    expect(Replicator.attribute_method?(:occurrences)).to eq true
    expect(Replicator.attribute_method?(:replicate_leaders)).to eq true
    expect(Replicator.attribute_method?(:user)).to eq true
  end

  it 'calls check_for_errors on go!' do
    allow(replicator).to receive(:check_for_errors).and_call_original

    expect(replicator).to receive(:check_for_errors)
    replicator.go!(base_event)
  end

  it 'calls morph_params on go!' do
    allow(replicator).to receive(:morph_params).and_call_original

    expect(replicator).to receive(:morph_params)
    replicator.go!(base_event)
  end

  describe '#go!' do
    before :each do
      # there must be at least one system user to receive notification emails
      create :admin, send_event_emails: true
    end

    it 'returns false if attributes have errors' do
      replicator.frequency = 'whenever'
      replicator.check_for_errors

      expect(replicator.errors.any?).to eq true

      expect(replicator.go!(base_event)).to eq false
    end

    context 'when errors exist' do
      it 'logs an array of errors' do
        expect(Rails.logger).to receive(:warn)

        # replicator's first occurrence matches the base event's dates and so will be logged
        replicator.go!(base_event)
      end
    end

    it 'creates a number of events equal to or one less than the value of occurrences' do
      expect(replicator.occurrences).to eq 3

      # replicator's first occurrence matches the base event's dates and so will be skipped
      expect { replicator.go!(base_event) }
        .to change { Event.count }
        .by(2)
    end

    it 'sends the EventMailer#replicated email' do
      allow(EventMailer).to receive_message_chain(:replicated, :deliver_later)

      expect(EventMailer).to receive(:replicated)

      replicator.go!(base_event)
    end
  end

  describe '#date_array' do
    it 'returns an array of hashes' do
      array = replicator.date_array

      expect(array.class).to eq Array

      expect(array[0].class).to eq Hash
    end
  end

  describe '#morph_params' do
    it 'changes strings into better values' do
      string_start = Time.now.to_s
      string_end = (Time.now + 3.hours).to_s
      string_occurrences = '5'
      string_replicate_leaders = 'false'

      replicator.tap do |rep|
        rep.start_time        = string_start
        rep.end_time          = string_end
        rep.occurrences       = string_occurrences
        rep.replicate_leaders = string_replicate_leaders
      end

      expect(replicator.start_time.is_a?(String)).to eq true
      expect(replicator.end_time.is_a?(String)).to eq true
      expect(replicator.occurrences.is_a?(String)).to eq true
      expect(replicator.replicate_leaders.is_a?(String)).to eq true

      replicator.morph_params

      expect(replicator.start_time.is_a?(Time)).to eq true
      expect(replicator.end_time.is_a?(Time)).to eq true
      expect(replicator.occurrences.is_a?(Integer)).to eq true
      expect(replicator.replicate_leaders.is_a?(FalseClass)).to eq true
    end
  end

  describe '#check_for_errors' do
    before :each do
      @bad_replicator = Replicator.new
      @bad_replicator.replicate_leaders = 'yessum'
      @bad_replicator.check_for_errors
    end

    context 'when .frequency is not an allowed value' do
      it 'adds an error' do
        expect(@bad_replicator.errors[:frequency][0]).to eq "must be either 'weekly' or 'monthly'"
      end
    end

    context 'when .occurrences is not present or positive' do
      it 'adds an error' do
        expect(@bad_replicator.errors[:occurrences][0]).to eq 'must be present and positive'
      end
    end

    context 'when start_time is not present' do
      it 'adds an error' do
        expect(@bad_replicator.errors[:start_time][0]).to eq 'must be present'
      end
    end

    context 'when end_time is not present' do
      it 'adds an error' do
        expect(@bad_replicator.errors[:end_time][0]).to eq 'must be present'
      end
    end
  end
end
