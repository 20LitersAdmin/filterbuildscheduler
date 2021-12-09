# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying a discarded technology', type: :system do
  before :each do
    sign_in create(:admin)
    @technology = create(:technology)
    @technology.discard
  end

  context 'via Rails Admin dashboard' do
    it 'can be deleted from index' do
      visit rails_admin.index_path(model_name: 'technology', scope: 'discarded')

      expect(page).to have_content @technology.name

      find('li.destroyable_member_link').click_link

      expect(page).to have_content 'Technology successfully deleted forever'

      expect { @technology.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end

    it 'can be deleted from show' do
      visit rails_admin.show_path(model_name: 'technology', id: @technology.id)

      expect(page).to have_content @technology.name

      find('li.destroyable_member_link').click_link

      expect(page).to have_content 'Technology successfully deleted forever'

      expect { @technology.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end
  end
end
