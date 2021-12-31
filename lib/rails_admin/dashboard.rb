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
            scheduler_links = {
              title: 'Scheduler Links',
              base_uri: '/',
              links: [
                { name: 'Builds that Need Leaders', link: 'events/lead' },
                { name: 'Contact Leaders', link: 'leaders' },
                { name: 'View Filter Build Events', link: 'events' }
              ]
            }
            leader_links = {
              title: 'Build Leader Links',
              base_uri: '/',
              links: [
                { name: 'View Filter Build Events', link: 'events' },
                { name: 'Sign Up To Lead', link: 'events/lead' }
              ]
            }
            data_manager_links = {
              title: 'Data Manager Links',
              base_uri: '/',
              links: [
                { name: 'View Filter Build Events', link: 'events' },
                { name: 'Events Needing Reports', link: 'admin/event?model_name=event&scope=needs_report' },
                { name: 'Manage Builder Communication Preferences', link: 'users/communication' }
              ]
            }
            inventory_links = {
              title: 'Inventory Links',
              base_uri: '/',
              links: [
                { name: 'Inventory Counts', link: 'inventories' },
                { name: 'New Inventory', link: 'inventories/new?type=manual' },
                { name: 'Receive Supplies', link: 'inventories/new?type=receiving' },
                { name: 'Ship Supplies', link: 'inventories/new?type=shipping' },
                { name: 'Print Inventory', link: 'inventories/paper' },
                { name: 'Print Labels', link: 'labels' }
              ]
            }
            event_management = {
              title: 'Event Management',
              base_uri: '/',
              links: [
                { name: 'Create new build event', link: 'events/new' },
                { name: 'Events Needing Reports', link: 'admin/event?model_name=event&scope=needs_report' },
                { name: 'Closed Events', link: 'admin/event?model_name=event&scope=closed' },
                { name: 'Cancelled Events', link: 'admin/event?model_name=event&scope=discarded' },
                { name: 'Reports', link: 'report' }
              ]
            }

            user_management = {
              title: 'User Management',
              base_uri: '/admin/user?model_name=user&scope=',
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
                { name: 'Manage Assemblies / Status', link: 'combinations' },
                { name: 'Print Labels', link: 'labels' },
                { name: 'Item Lists', link: 'lists' },
                { name: 'Order Items', link: 'inventories/order_all' },
                { name: 'Goal Items', link: 'inventories/order_goal' }
              ]
            }

            technology_management[:links] << { name: 'Items Below Minimum!', link: 'inventories/order' } if Part.below_minimums.any? || Material.below_minimums.any?

            email_management = {
              title: 'Email Sync System',
              base_uri: '/',
              links: [
                { name: 'Oauth User List', link: 'auth' },
                { name: 'Sign in link', link: 'auth/in' },
                { name: 'Sign out link', link: 'auth/out' },
                { name: 'Stored emails', link: 'admin/email' },
                { name: 'Stored organizations', link: 'admin/organization' }
              ]
            }

            # add specific blocks based upon permissions using current_user variable
            instances = []

            if current_user.is_admin?
              # assign everything except Email Management
              instances = [
                scheduler_links,
                leader_links,
                data_manager_links,
                inventory_links,
                event_management,
                technology_management,
                user_management
              ]
            else
              # assign based upon role
              instances << scheduler_links if current_user.is_scheduler?

              instances << data_manager_links if current_user.is_data_manager?

              instances << leader_links if current_user.is_leader?

              instances << inventory_links if current_user.does_inventory

              # NOTE: admins, leaders, schedulers and data managers
              instances << event_management if current_user.can_edit_events?
            end

            # Special case:
            instances << email_management if current_user.is_oauth_admin?

            @management_instances = instances.flatten.uniq

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
