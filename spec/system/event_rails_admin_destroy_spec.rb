# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying a discarded event', type: :system do
  before :each do
    sign_in create(:admin)
    @event = create(:event)
    @event.discard
  end

  context 'via Rails Admin dashboard' do
    it 'can be deleted from index' do
      visit rails_admin.index_path(model_name: 'event', scope: 'discarded')

      expect(page).to have_content @event.title

      find('li.destroyable_member_link').click_link

      expect(page).to have_content 'Event successfully deleted forever'

      expect { @event.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end

    fit 'can be deleted from show' do
      visit rails_admin.show_path(model_name: 'event', id: @event.id)

      expect(page).to have_content @event.title

      find('li.destroyable_member_link').click_link

      expect(page).to have_content 'Event successfully deleted forever'

      expect { @event.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end
  end
end
