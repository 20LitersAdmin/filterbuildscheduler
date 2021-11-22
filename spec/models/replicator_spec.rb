# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Replicator, type: :model do
  let(:base_event) { create :event }
  let(:replicator) { build :replicator, event_id: base_event.id, start_time: base_event.start_time, end_time: base_event.end_time }

  it 'has attributes' do
    expect(Replicator.attribute_method?(:event_id)).to eq true
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
    replicator.go!
  end

  it 'calls morph_params on go!' do
    allow(replicator).to receive(:morph_params).and_call_original

    expect(replicator).to receive(:morph_params)
    replicator.go!
  end

  describe '#go!' do
    before :each do
      # there must be at least one system user to receive notification emails
      FactoryBot.create(:admin, send_notification_emails: true)
    end

    it 'returns false if attributes have errors' do
      replicator.event_id = nil
      replicator.check_for_errors

      expect(replicator.errors.any?).to eq true

      expect(replicator.go!).to eq false
    end

    context 'when errors exist' do
      it 'logs an array of errors' do
        expect(Rails.logger).to receive(:warn)

        # replicator's first occurrence matches the base event's dates and so will be logged
        replicator.go!
      end
    end

    it 'creates a number of events equal to or one less than the value of occurrences' do
      expect(replicator.occurrences).to eq 3

      # replicator's first occurrence matches the base event's dates and so will be skipped
      expect { replicator.go! }
        .to change { Event.count }
        .by(2)
    end

    it 'sends the EventMailer#replicated email' do
      allow(EventMailer).to receive(:delay).and_return(EventMailer)
      allow(EventMailer).to receive(:replicated).and_call_original

      expect(EventMailer).to receive(:replicated)

      replicator.go!
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
    pending 'changes strings into better values'
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
        expect(@bad_replicator.errors[:occurrences][0]).to eq "must be present and positive"
      end
    end

    context 'when event_id is not present' do
      it 'adds an error' do
        expect(@bad_replicator.errors[:event_id][0]).to eq 'must be present'
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

    context 'when replicate_leaders is not a boolean or castable' do
      it 'adds an error' do
        expect(@bad_replicator.errors[:replicate_leaders][0]).to eq 'must be either true or false'
      end
    end
  end
end
