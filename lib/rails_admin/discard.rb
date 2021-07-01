# frozen_string_literal: true

require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Discard < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :visible? do
          if %w[Component Event Location Material Part Registration Supplier Technology User].include? bindings[:object].class.to_s
            !bindings[:object].discarded?
          else
            true
          end
        end

        register_instance_option :member do
          true
        end

        register_instance_option :route_fragment do
          'delete'
        end

        register_instance_option :http_methods do
          %i[get delete]
        end

        register_instance_option :authorization_key do
          :destroy
        end

        register_instance_option :controller do
          proc do
            @object.discard
            flash[:success] = t('admin.flash.successful', name: @model_config.label, action: t('admin.actions.delete.done'))
            redirect_to back_or_index
          end
        end

        register_instance_option :link_icon do
          'icon-trash'
        end
      end
    end
  end
end
