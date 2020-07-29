# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Replicator, type: :model do
  before :each do
    @event = create(:event)
  end

  it 'has attributes' do
    expect(Replicator.attribute_method?(:event_id)).to eq true
    expect(Replicator.attribute_method?(:start_time)).to eq true
    expect(Replicator.attribute_method?(:end_time)).to eq true
    expect(Replicator.attribute_method?(:frequency)).to eq true
    expect(Replicator.attribute_method?(:interval)).to eq true
    expect(Replicator.attribute_method?(:occurrences)).to eq true
    expect(Replicator.attribute_method?(:replicate_leaders)).to eq true
    expect(Replicator.attribute_method?(:initiator)).to eq true
  end

  it 'calls morph_params on initialize' do
    expect_any_instance_of(Replicator).to receive(:morph_params)

    FactoryBot.build(:replicator, event_id: @event.id, start_time: @event.start_time, end_time: @event.end_time)
  end

  it 'calls check_for_errors on initialize' do
    expect_any_instance_of(Replicator).to receive(:check_for_errors)

    FactoryBot.build(:replicator, event_id: @event.id, start_time: @event.start_time, end_time: @event.end_time)
  end

  describe '#go!' do
    before :each do
      # --->                            there must be at least one system user to receive notification emails
      @user = FactoryBot.create(:admin, send_notification_emails: true)
      @replicator = Replicator.new(event_id: @event.id, start_time: @event.start_time, end_time: @event.end_time, frequency: 'monthly', occurrences: 3, replicate_leaders: false, initiator: @user)
    end

    it 'returns false if attributes have errors' do
      @replicator.event_id = nil
      @replicator.check_for_errors

      expect(@replicator.errors.any?).to eq true

      expect(@replicator.go!).to eq false
    end

    context 'when errors exist' do
      it 'logs an array of errors' do
        expect(Rails.logger).to receive(:warn)

        # @replicator's first occurrence matches the base event's dates and so will be logged
        @replicator.go!
      end
    end

    it 'creates a number of events equal to or one less than the value of occurrences' do
      expect(@replicator.occurrences).to eq 3

      # @replicator's first occurrence matches the base event's dates and so will be logged
      expect { @replicator.go! }.to change { Event.count }.by(2)
    end

    it 'sends the EventMailer#replicated email' do
      allow(EventMailer).to receive_message_chain('replicated.deliver_now')

      expect(EventMailer).to receive(:replicated)

      @replicator.go!
    end
  end

  describe '#date_array' do
    it 'returns an array of hashes' do
      @replicator = FactoryBot.build(:replicator, event_id: @event.id, start_time: @event.start_time, end_time: @event.end_time)

      array = @replicator.date_array

      expect(array.class).to eq Array

      expect(array[0].class).to eq Hash
    end
  end

  describe '#morph_params' do
    it 'changes strings into better values' do
    end
  end

  describe '#check_for_errors' do
    before :each do
      @replicator = Replicator.new
      # Replicator.new calls check_for_errors on initialize
    end

    context 'when .frequency is not an allowed value' do
      it 'adds an error' do
        expect(@replicator.errors[:frequency][0]).to eq "must be either 'weekly' or 'monthly'"
      end
    end

    context 'when .occurrences is not present or positive' do
      it 'adds an error' do
        expect(@replicator.errors[:occurrences][0]).to eq "must be present and positive"
      end
    end

    context 'when event_id is not present' do
      it 'adds an error' do
        expect(@replicator.errors[:event_id][0]).to eq 'must be present'
      end
    end

    context 'when start_time is not present' do
      it 'adds an error' do
        expect(@replicator.errors[:start_time][0]).to eq 'must be present'
      end
    end

    context 'when end_time is not present' do
      it 'adds an error' do
        expect(@replicator.errors[:end_time][0]).to eq 'must be present'
      end
    end

    context 'when replicate_leaders is not a boolean' do
      it 'adds an error' do
        expect(@replicator.errors[:replicate_leaders][0]).to eq 'must be boolean'
      end
    end
  end
end
