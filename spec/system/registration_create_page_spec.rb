# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin creating event registrations', type: :system do
  let(:event) { create :event }
  let(:admin) { create :admin }

  context 'for a builder' do
    before do
      sign_in admin
      visit new_event_registration_path event
    end

    it 'shows the registration form' do
      expect(page).to have_content "Register someone for #{event.full_title}"
      expect(page).to have_field 'registration_user_fname'
      expect(page).to have_css("input[name='commit']")
    end

    context 'when the event allows guests' do
      it 'shows guests field' do
        expect(event.allow_guests?).to eq true
        expect(page).to have_field 'registration_guests_registered'
      end
    end

    context 'when the event does not allow guests' do
      before do
        event.update(allow_guests: false)
        visit new_event_registration_path event
      end

      it 'does not show guests field' do
        expect(event.allow_guests?).to eq false
        expect(page).not_to have_field 'registration_guests_registered'
      end
    end

    context 'can be filled out and submitted' do
      it 'using the Create & New button' do
        user = build(:user)

        fill_in 'registration_user_email', with: user.email
        fill_in 'registration_user_fname', with: user.fname
        fill_in 'registration_user_lname', with: user.lname
        check 'registration_user_email_opt_out'

        click_button 'Create & New'

        expect(page).to have_content 'Registration successful!'
        expect(page).to have_content "Register someone for #{event.full_title}"
        expect(page).to have_field 'registration_user_fname'

        saved_user = User.find_by(email: user.email)

        expect(saved_user.email_opt_out).to eq true
      end

      it 'by email only for a user that exists' do
        user = create(:user)

        fill_in 'registration_user_email', with: user.email

        click_submit

        expect(page).to have_content 'Registration successful!'
        expect(page).to have_content "#{event.full_title} Registrations"
        builder_tbl_text = page.all('table#builders_tbl td').map(&:text)
        expect(builder_tbl_text).to have_content user.name
      end

      context 'for a new user' do
        let(:user) { build :user }

        it 'with email only isn\'t successful' do
          fill_in 'registration_user_email', with: user.email
          click_submit

          expect(page).to have_content 'First Name can\'t be blank | Last Name can\'t be blank'
          expect(page).to have_content "Register someone for #{event.full_title}"
          expect(page).to have_css('input[name="commit"]')
        end

        it 'with all fields is successful' do
          fill_in 'registration_user_email', with: user.email
          fill_in 'registration_user_fname', with: user.fname
          fill_in 'registration_user_lname', with: user.lname

          click_submit

          builder_tbl_text = page.all('table#builders_tbl td').map(&:text)

          expect(page).to have_content "#{event.full_title} Registrations"
          expect(builder_tbl_text).to have_content user.name

          expect(User.last.email).to eq user.email
        end
      end
    end
  end

  context 'for a leader' do
    it 'via the events/:id/leaders page' do
      sign_in admin
      user = create(:leader)
      user.primary!
      user.technologies << event.technology
      user.save

      visit leaders_event_path event

      expect(page).to have_content 'Registered leaders:'
      expect(page).to have_content 'Other leaders:'
      expect(page).to have_css('table#other_leaders_tbl', text: user.name)

      click_link 'Register'

      expect(page).to have_content "Registered #{user.name}"
      expect(page).to have_css('table#leaders_tbl', text: user.name)
    end
  end
end
