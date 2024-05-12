# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Event edit page', type: :system do
  let(:event) { create :event }

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit edit_event_path event

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit edit_event_path event

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryists redirects to home page' do
      sign_in create(:inventoryist)
      visit edit_event_path event

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit edit_event_path event

      expect(page).to have_content event.title
    end

    it 'data managers shows the page' do
      sign_in create(:data_manager)
      visit edit_event_path event

      expect(page).to have_content event.title
    end

    it 'leaders shows the page' do
      sign_in create(:leader)
      visit edit_event_path event

      expect(page).to have_content event.title
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)
      visit edit_event_path event

      expect(page).to have_content event.title
    end
  end

  it 'allows for editing' do
    sign_in create(:admin)
    visit edit_event_path event

    expect(page).to have_content event.title

    fill_in 'event_title', with: 'new title'
    fill_in 'event_description', with: 'new description'
    click_button 'Submit'

    expect(page).to have_content 'Event updated.'

    expect(event.reload.title).to eq 'new title'
    expect(event.reload.description).to eq 'new description'
  end

  context 'allows for canceling' do
    let!(:registrations) { create_list :registration, 3, event: }

    it 'which discards the event and all registrations' do
      allow(RegistrationMailer).to receive(:event_cancelled).and_call_original
      sign_in create(:admin)
      visit edit_event_path event

      expect(page).to have_content event.title

      expect(page).to have_link 'Cancel Event'

      click_link 'Cancel Event'

      expect(page).to have_content 'Upcoming Builds'

      expect(event.reload.discarded_at).not_to be_nil
      expect(event.registrations.pluck(:discarded_at).uniq).not_to include nil
      expect(RegistrationMailer).to have_received(:event_cancelled).exactly(3).times
    end
  end

  it 'allows for duplicating' do
    sign_in create(:admin)
    visit edit_event_path event

    expect(page).to have_content event.title

    click_link 'Duplicate'

    expect(page).to have_content "Create a copy of #{event.title}"
    expect(page).to have_current_path(new_event_path(source_event: event.id))

    fill_in 'event_title', with: 'Dup event'

    click_submit

    expect(page).to have_content 'Upcoming Builds'

    dup_event = Event.last

    expect(dup_event.title).to eq 'Dup event'
    expect(event.technology).to eq dup_event.technology
    expect(event.location).to eq dup_event.location
    expect(event.start_time).to eq dup_event.start_time
  end

  it 'allows for replicating', js: true do
    sign_in create(:admin)
    visit edit_event_path event

    expect(page).to have_content event.title

    click_link 'Replicate'

    expect(page).to have_content 'Replicate this event:'

    select 'weekly', from: 'replicator_frequency'
    fill_in 'replicator_occurrences', with: 3

    # first instance is a duplicate, so it's skipped
    expect { click_button 'Replicate' }
      .to change { Event.all.size }
      .by(2)
  end
end
