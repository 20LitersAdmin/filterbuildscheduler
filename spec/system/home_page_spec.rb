# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  after :all do
    clean_up!
  end

  context 'an Admin user' do
    it 'goes to the homepage' do
      sign_in FactoryBot.create(:admin)
      visit '/'

      expect(page).to have_content 'Admin'
    end

    context 'when public events are present' do
      it 'shows the events' do
        3.times do
          FactoryBot.create(:event)
        end
        sign_in FactoryBot.create(:admin)
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{Event.first.id}")
        expect(page).to have_selector(:css, "div#event_#{Event.second.id}")
        expect(page).to have_selector(:css, "div#event_#{Event.third.id}")
      end
    end

    context 'when private events are present' do
      it 'shows the events' do
        3.times do
          FactoryBot.create(:event, is_private: true)
        end
        sign_in FactoryBot.create(:admin)
        visit '/'

        expect(page).to have_content 'Upcoming Builds'
        expect(page).to have_selector(:css, "div#event_#{Event.first.id}")
        expect(page).to have_selector(:css, "div#event_#{Event.second.id}")
        expect(page).to have_selector(:css, "div#event_#{Event.third.id}")
      end
    end

    context 'when past events are present' do
      before :each do
        3.times do
          FactoryBot.create(:past_event)
        end
        sign_in FactoryBot.create(:admin)
        visit '/'
      end

      it 'shows the events' do
        expect(page).to have_content 'Open Builds (report is missing)'
        expect(page).to have_selector(:css, "div#event_#{Event.first.id}")
        expect(page).to have_selector(:css, "div#event_#{Event.second.id}")
        expect(page).to have_selector(:css, "div#event_#{Event.third.id}")
      end

      it 'links directly to the edit page' do
        expect(page).to have_link('', href: edit_event_path(Event.first))
        expect(page).to have_link('', href: edit_event_path(Event.second))
        expect(page).to have_link('', href: edit_event_path(Event.third))
      end
    end
  end

  context 'a Leader user' do
    it 'goes to the homepage' do
      sign_in FactoryBot.create(:leader)
      visit '/'

      expect(page).to have_content 'Available functions:'
    end

    context 'when public events are present' do
      it 'shows the events' do
      end
    end

    context 'when private events are present' do
      it 'shows the events' do
      end
    end

    context 'when past events are present' do
      it 'links directly to the edit page' do
      end
    end
  end

  context 'a Builder user' do
    it 'goes to homepage' do
      sign_in FactoryBot.create(:user)
      visit '/'

      expect(page).to have_content 'My Account'
    end

    context 'when public events are present' do
      it 'shows the events' do
      end
    end

    context 'when private events are present' do
      it 'doesn\'t show the events' do
      end
    end

    context 'when past events are present' do
      it 'doesn\'t show the events' do
      end
    end
  end

  context 'no user' do
    it 'goes to the homepage' do
      visit '/'

      expect(page).to have_content 'Want a custom build event for your group?'
    end

    context 'when public events are present' do
      it 'shows the events' do
      end
    end

    context 'when private events are present' do
      it 'doesn\'t show the events' do
      end
    end

    context 'when past events are present' do
      it 'doesn\'t show the events' do
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

  context 'when public events are present' do
  end

  context 'when private events are present' do
  end
end
