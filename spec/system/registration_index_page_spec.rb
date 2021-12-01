# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin viewing event registrations index', type: :system do
  let(:event) { create :event }
  let(:registrations) { create_list :registration, 5, event: event }
  let(:leader_reg) { create_list :registration_leader, 2, event: event }
  let(:admin) { create :admin }

  it 'can view registered builders and leaders' do
    registrations
    leader_reg
    sign_in admin
    visit event_registrations_path event

    expect(page).to have_content "#{event.full_title} Registrations"
    expect(page).to have_content 'Leaders registered:'
    expect(page).to have_css 'table#leaders_tbl tbody tr', count: 2
    expect(page).to have_content 'Builders registered:'
    expect(page).to have_css 'table#builders_tbl tbody tr', count: 5
  end

  it 'can discard a registration' do
    registrations
    leader_reg
    sign_in admin
    visit event_registrations_path event

    expect(page).to have_content "#{event.full_title} Registrations"

    registration = registrations.first

    click_link "discard_#{registration.id}"

    expect(page).to have_content 'Registration discarded, but can be restored.'

    expect(page).to have_content 'Discarded registrations:'

    expect(registration.reload.discarded_at).not_to be_nil
  end

  it 'can restore a registration' do
    registrations
    leader_reg
    sign_in admin

    registration = registrations.first
    registration.discard

    visit event_registrations_path event

    expect(page).to have_content "#{event.full_title} Registrations"

    expect(page).to have_content 'Discarded registrations:'

    click_link "restore_#{registration.id}"

    expect(page).to have_content 'Registration restored!'

    expect(page).not_to have_content 'Discarded registrations:'

    expect(registration.reload.discarded_at).to be_nil
  end

  it 'can restore all discarded registrations at once' do
    registrations
    leader_reg
    sign_in admin

    registrations.each(&:discard)

    expect(Registration.discarded.size).to eq 5

    visit event_registrations_path event

    expect(page).to have_content "#{event.full_title} Registrations"

    expect(page).to have_content 'Discarded registrations:'

    click_link 'Restore All'

    expect(page).to have_content '5 discarded registrations restored!'

    expect(page).not_to have_content 'Discarded registrations:'
  end

  it 'can resend a confirmation' do
    registrations
    leader_reg
    sign_in admin

    registration = registrations.first

    visit event_registrations_path event

    expect(page).to have_content "#{event.full_title} Registrations"

    click_link("reconfirm_#{registration.id}")

    expect(page).to have_content "Re-sent confirmation to #{registration.user.name}"
  end

  it 'can resend all confirmations at once' do
    registrations
    leader_reg
    sign_in admin

    visit event_registrations_path event

    expect(page).to have_content "#{event.full_title} Registrations"

    click_link('Resend All Confirmations')

    expect(page).to have_content 'Sending confirmation emails to 7 registrants'
  end
end
