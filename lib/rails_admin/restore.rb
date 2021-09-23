# frozen_string_literal: true

require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Restore < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :visible? do
          object = bindings[:object]

          # Object's class must include Discard::Model AND
          # Object must be discarded
          object.class.include?(Discard::Model) &&
            object.discarded?
        end

        register_instance_option :member do
          true
        end

        register_instance_option :link_icon do
          'icon-circle-arrow-up'
        end

        register_instance_option :controller do
          proc do
            @object.undiscard
            flash[:success] = t('admin.flash.successful', name: @model_config.label, action: t('admin.actions.restore.done'))
            redirect_to request.referrer
          end
        end
      end
    end
  end
end
