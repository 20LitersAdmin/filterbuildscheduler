# frozen_string_literal: true

require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Discardable < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :visible? do
          object = bindings[:object]

          # if Object is a User, it can't be an Admin User
          # if Object is not a User, it's class must include Discard::Model
          (object.instance_of?(User) && !object.is_admin?) ||
            (!object.instance_of?(User) && object.class.include?(Discard::Model))
        end

        register_instance_option :member do
          true
        end

        register_instance_option :route_fragment do
          'discard'
        end

        register_instance_option :http_methods do
          %i[get discard]
        end

        register_instance_option :authorization_key do
          :discard
        end

        register_instance_option :controller do
          proc do
            # TODO: Second deploy
            @object.discard
            flash[:success] = t('admin.flash.successful', name: @model_config.label, action: t('admin.actions.discard.done'))
            redirect_to request.referrer
          end
        end

        register_instance_option :link_icon do
          'icon-ban-circle'
        end
      end
    end
  end
end