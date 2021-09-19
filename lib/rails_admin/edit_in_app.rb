# frozen_string_literal: true

require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class EditInApp < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :visible? do
          bindings[:object].instance_of?(Event) &&
            bindings[:object]&.kept?
        end

        register_instance_option :member do
          true
        end

        register_instance_option :route_fragment do
          'edit_in_app'
        end

        register_instance_option :http_methods do
          %i[get edit_in_app]
        end

        register_instance_option :authorization_key do
          :edit_in_app
        end

        register_instance_option :controller do
          proc do
            redirect_to main_app.edit_event_path(@object)
          end
        end

        register_instance_option :link_icon do
          'icon-pencil'
        end

        register_instance_option :pjax? do
          false
        end
      end
    end
  end
end
