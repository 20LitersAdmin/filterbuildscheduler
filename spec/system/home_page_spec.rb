# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  context 'an Admin user' do
    before :each do
      sign_in create(:admin)
    end

    it 'goes to the homepage' do
      visit '/'

      expect(page).to have_content 'Admin'
    end

    context 'when public events are present' do
      let(:events) { create_list :event, 3 }

      it 'shows the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).to have_selector(:css, "div#event_#{events.third.id}")
      end
    end

    context 'when private events are present' do
      let(:events) { create_list :event, 3, is_private: true }

      it 'shows the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).to have_selector(:css, "div#event_#{events.third.id}")
      end
    end
  end

  context 'a Leader user' do
    before :each do
      sign_in create(:leader)
    end

    it 'goes to the homepage' do
      visit '/'

      expect(page).to have_content 'Admin'
    end

    context 'when public events are present' do
      let(:events) { create_list :event, 3 }

      it 'shows the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).to have_selector(:css, "div#event_#{events.third.id}")
      end
    end

    context 'when private events are present' do
      let(:events) { create_list :event, 3, is_private: true }

      it 'shows the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).to have_selector(:css, "div#event_#{events.third.id}")
      end
    end
  end

  context 'a Builder user' do
    before :each do
      sign_in create(:user)
    end

    it 'goes to homepage' do
      visit '/'

      expect(page).to have_content 'My Account'
    end

    context 'when public events are present' do
      let(:events) { create_list :event, 3 }

      it 'shows the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).to have_selector(:css, "div#event_#{events.third.id}")
      end
    end

    context 'when private events are present' do
      let(:events) { create_list :event, 3, is_private: true }

      it 'doesn\'t show the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).not_to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).not_to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).not_to have_selector(:css, "div#event_#{events.third.id}")
      end
    end
  end

  context 'no user' do
    it 'goes to the homepage' do
      visit '/'

      expect(page).to have_content 'Want a custom build event for your group?'
    end

    context 'when public events are present' do
      let(:events) { create_list :event, 3 }

      it 'shows the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).to have_selector(:css, "div#event_#{events.third.id}")
      end
    end

    context 'when private events are present' do
      let(:events) { create_list :event, 3, is_private: true }

      it 'doesn\'t show the events' do
        events
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).not_to have_selector(:css, "div#event_#{events.first.id}")
        expect(page).not_to have_selector(:css, "div#event_#{events.second.id}")
        expect(page).not_to have_selector(:css, "div#event_#{events.third.id}")
      end
    end
  end

  context 'has some static links' do
    it 'has a Give button' do
      visit '/'

      expect(page).to have_link 'Give'
    end

    it 'has a logo that links to 20liters.org' do
      visit '/'

      expect(page).to have_link('', href: 'https://20liters.org')
    end
  end
end
