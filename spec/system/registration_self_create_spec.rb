# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User self-registering for an event', type: :system do
  let(:event) { create :event }

  context 'logged in user' do
    context 'shows the registration_signedin partial' do
      it 'without leader checkbox for a builder' do
        user = create(:user)
        sign_in user
        visit event_path event

        expect(page).to have_content event.full_title
        expect(page).to have_content user.name
        expect(page).to have_field 'registration_accept_waiver'
        expect(page).to have_css("input[name='commit']")

        expect(page).to_not have_field 'registration_user_fname'
      end
    end

    context 'can be filled out and submitted' do
      it 'to register a builder and send an email' do
        user = create(:user)
        sign_in user
        visit event_path event

        check 'registration_accept_waiver'

        expect { click_submit }
          .to have_enqueued_mail(RegistrationMailer, :created).once

        expect(page).to have_content 'Registration successful!'
        expect(page).to have_content user.name
        expect(page).to have_link 'Change/Cancel Registration'
      end
    end
  end

  context 'when anon user' do
    before :each do
      visit event_path event
    end

    it 'shows the registration_anonymous partial' do
      expect(page).to have_content event.full_title

      expect(page).to have_field 'registration_user_fname'
      expect(page).to have_field 'registration_accept_waiver'
      expect(page).to have_css("input[name='commit']")
    end

    it 'can be filled out and submitted, which sends the user\'s info to Kindful' do
      user = build(:user)

      fill_in 'registration_user_fname', with: user.fname
      fill_in 'registration_user_lname', with: user.lname
      fill_in 'registration_user_email', with: user.email
      check 'registration_accept_waiver'

      expect_any_instance_of(KindfulClient).to receive(:import_user)

      click_submit

      expect(User.last.fname).to eq user.fname

      expect(page).to have_content 'Registration successful!'
      expect(page).to have_content user.name
      expect(page).to have_link 'Change/Cancel Registration'
    end

    it 'can be filled out using an existing email' do
      user = create(:user)

      fill_in 'registration_user_email', with: user.email
      check 'registration_accept_waiver'

      click_submit

      expect(page).to have_content 'Registration successful!'
      expect(page).to have_content user.name
      expect(page).to have_link 'Change/Cancel Registration'
    end
  end
end
