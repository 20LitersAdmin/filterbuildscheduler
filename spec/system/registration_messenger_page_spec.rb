# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Email registered users:', type: :system do
  let(:event) { create :event, max_registrations: 40 }
  let(:registrations) { create_list :registration, 5, event: }

  context 'anon user' do
    it 'can\'t visit the messenger page' do
      visit messenger_event_registrations_path event
      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end
  end

  context 'builder' do
    it 'can\'t visit the messenger page' do
      user = create(:user)
      sign_in user
      visit messenger_event_registrations_path event

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'leader' do
    before :each do
      @user = create(:leader)
      sign_in @user
      registrations
      visit messenger_event_registrations_path event
    end

    it 'can visit the messenger page' do
      expect(page).to have_content 'Send a message to all 5 builders?'
      expect(page).to have_field 'subject'
      expect(page).to have_field 'message'
      expect(page).to have_button 'Send Message'
    end

    it 'can fill out and submit the form' do
      fill_in 'subject', with: 'Leaders can send messages'
      fill_in 'message', with: "My name is #{@user.name} and I'm a leader"
      click_button 'Send Message'

      expect(page).to have_content "#{event.full_title} Registrations"
    end
  end

  context 'admin' do
    before :each do
      @user = create(:admin, send_event_emails: true)
      sign_in @user
      registrations
      visit messenger_event_registrations_path event
    end

    it 'can visit the messenger page' do
      expect(page).to have_content 'Send a message to all'
      expect(page).to have_field 'subject'
      expect(page).to have_field 'message'
      expect(page).to have_button 'Send Message'
    end

    it 'can fill out and submit the form, which queues up some emails' do
      fill_in 'subject', with: 'Admins can send messages'
      fill_in 'message', with: "My name is #{@user.name} and I'm a leader"

      expect { click_button 'Send Message' }
        .to have_enqueued_mail(EventMailer, :messenger).exactly(5).times

      expect(page).to have_content "#{event.full_title} Registrations"
    end
  end
end
