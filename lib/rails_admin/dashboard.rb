# frozen_string_literal: true

require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Dashboard < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :root? do
          true
        end

        register_instance_option :breadcrumb_parent do
          nil
        end

        register_instance_option :controller do
          proc do
            event_management = {
              title: 'Event Management',
              base_uri: '/',
              links: [
                { name: 'Create new build event', link: 'events/new' },
                { name: 'Contact Leaders', link: 'leaders' },
                { name: 'Assign Leaders', link: 'events/lead' },
                { name: 'Manage Builder Communication Preferences', link: 'users/communication' },
                { name: 'Closed Events', link: 'admin/event&scope=closed' },
                { name: 'Cancelled Events', link: 'admin/event&scope=discarded' },
              ]
            }

            user_management = {
              title: 'User Management',
              base_uri: 'admin/user?model_name=user&scope=',
              links: [
                { name: 'Build Leaders', link: 'leaders' },
                { name: 'Builders', link: 'builders' },
                { name: 'Inventoryists', link: 'inventoryists' },
                { name: 'Admins', link: 'admins' }
              ]
            }

            technology_management = {
              title: 'Technology Management',
              base_uri: '/',
              links: [
                { name: 'Edit/Update Technologies', link: 'admin/technology' },
                { name: 'Item and Price lists', link: 'technologies' },
                { name: 'Labels', link: 'labels' },
                { name: 'Manage Assemblies', link: '#' },
                { name: 'Order Items', link: 'inventories/order_all' }
              ]
            }

            technology_management[:links] << { name: 'Items Below Minimum!', link: 'inventories/order' } if Part.below_minimums.any? || Material.below_minimums.any?

            # TODO: Doesn't migrate to VWF
            email_management = {
              title: 'Email Sync System',
              base_uri: '/',
              links: [
                { name: 'Oauth User List', link: 'auth' },
                { name: 'Manage Oauth Users', link: 'admin/oauth_user' },
                { name: 'Sign in link', link: 'auth/in' },
                { name: 'Sign out link', link: 'auth/out' },
                { name: 'Stored emails', link: 'admin/email' },
                { name: 'Stored organizations', link: 'admin/organization' },
              ]
            }

            @management_instances = [
              event_management,
              user_management,
              technology_management,
              email_management
            ]

            render action: @action.template_name, status: 200
          end
        end

        register_instance_option :route_fragment do
          ''
        end

        register_instance_option :link_icon do
          'icon-home'
        end

        register_instance_option :statistics? do
          false
        end

      end
    end
  end
end
