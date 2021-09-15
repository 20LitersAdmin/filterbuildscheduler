# frozen_string_literal: true

require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Assemble < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :visible? do
          %w[Component Part Technology].include?(bindings[:object].class.to_s) &&
            bindings[:object].kept?
        end

        register_instance_option :member do
          true
        end

        register_instance_option :link_icon do
          'icon-wrench'
        end

        register_instance_option :show_in_navigation do
          false
        end

        register_instance_option :show_in_sidebar do
          false
        end

        register_instance_option :enabled? do
          %w[Technology Component Part].include? bindings[:object].class.name
        end

        register_instance_option :pjax? do
          false
        end

        # This block is evaluated in the context of the controller when action is called
        # You can access:
        # - @objects if you're on a model scope
        # - @abstract_model & @model_config if you're on a model or object scope
        # - @object if you're on an object scope
        register_instance_option :controller do
          proc do
            respond_to do |format|
              format.html { redirect_to "/assemble/#{@object.uid}" }
            end
          end
        end
      end
    end
  end
end
