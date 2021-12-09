# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying a discarded location', type: :system do
  before :each do
    sign_in create(:admin)
    @location = create(:location)
    @location.discard
  end

  context 'via Rails Admin dashboard' do
    it 'can be deleted from index' do
      visit rails_admin.index_path(model_name: 'location', scope: 'discarded')

      expect(page).to have_content @location.name

      find('li.destroyable_member_link').click_link

      expect(page).to have_content 'Location successfully deleted forever'

      expect { @location.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it 'can be deleted from show' do
      visit rails_admin.show_path(model_name: 'location', id: @location.id)

      expect(page).to have_content @location.name

      find('li.destroyable_member_link').click_link

      expect(page).to have_content 'Location successfully deleted forever'

      expect { @location.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end
  end
end
