# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationReminderJob, type: :job do
  let(:job) { RegistrationReminderJob.new }
  let(:event) { create :event_upcoming }
  let(:registration) { create :registration, event: event }
  let(:mail_message) { instance_double ActionMailer::MessageDelivery }

  it 'queues as registration_reminder' do
    expect(job.queue_name).to eq 'registration_reminder'
  end

  describe '#perform' do
    before do
      allow(Event).to receive_message_chain(:pre_reminders, :future, :within_days).with(2).and_return(Event.all)

      allow(EventMailer).to receive(:remind_admins).with(event).and_return(mail_message)
      allow(RegistrationMailer).to receive(:reminder).with(registration).and_return(mail_message)
      allow(mail_message).to receive(:deliver_now).and_return(true)
    end

    it 'calls Event.pre_reminders.future.within_days(2)' do
      expect(Event).to receive_message_chain(:pre_reminders, :future, :within_days).with(2)

      job.perform
    end

    it 'calls EventMailer.remind_admins' do
      expect(EventMailer).to receive(:remind_admins).with(event)

      job.perform
    end

    it 'calls RegistrationMailer.reminder' do
      expect(RegistrationMailer).to receive(:reminder).with(registration)

      job.perform
    end

    it 'updates registrations.reminder_sent_at' do
      expect { job.perform }
        .to change { registration.reload.reminder_sent_at&.to_date }
        .from(nil).to(Time.zone.now.to_date)
    end

    it 'updates event.reminder_sent_at' do
      expect { job.perform }
        .to change { event.reload.reminder_sent_at&.to_date }
        .from(nil).to(Time.zone.now.to_date)
    end
  end
end
