# README
## Slim Down Inventory project

* Run & fix tests
  - Concern test is green
  - Helper test is green
  - Job tests are green
  - Model tests are green
  - Request test is green
  - Service tests are green
  - System tests are red (258 tests , 85 failures)

* New System tests:
  - view_all_events
    - view_events_that_need_leaders_via_rails_admin
    - view_events_that_need_leaders_via_events_lead
    - view_future_events
    - view_events_that_need_reports
    - view_closed_events
    - view_discarded_events
  - discard_an_event_via_rails_admin
  - discard_an_event_via_events_edit
  - destroy_an_event
  - restore_an_event
  - show_an_event_in_app_via_rails_admin
  - edit_an_event_in_app_via_rails_admin
  - discard_a_registration_via_registrations_index
  - destroy_a_registration
  - restore_a_registration_via_rails_admin
  - restore_a_registration_via_registrations_index
  - retore_all_discarded_registrations (RegistrationsController#restore_all)
  - register_a_leader_for_an_event (EventsController#leaders)
  - register_a_builder_for_an_event (RegistrationsController#new)
  - resend_all_confirmation_emails (RegistrationsController#index)
  - discard_a_part
  - destroy_a_part
  - restore_a_part
  - discard_a_material
  - destroy_a_material
  - restore_a_material
  - discard_a_component
  - destroy_a_component
  - restore_a_component
  - discard_a_technology
  - destroy_a_technology
  - restore_a_technology
  - discard_a_location
  - destroy_a_location
  - restore_a_location
  - discard_a_supplier
  - destroy_a_supplier
  - restore_a_supplier
  - show_a_user_via_rails_admin
  - show_a_user_via_users_show
  - edit_a_user_via_rails_admin
  - edit_a_user_via_app
  - discard_a_user
  - destroy_a_user
  - restore_a_user
  - password_reset_via_admin
  - contact_leaders (/leaders; users#leaders)
  - combinations_index_page
  - combinations_show_page
  - combinations_edit_page
  - create_an_assembly
  - edit_an_assembly
  - destroy_an_assembly
  - replicate_an_event (with JS for event dates)
  - duplicate_an_event
  - view_report_page
  - view_volunteer_report
  - view_leader_report
  - view_donation_list
  - view_inventory_history
  - view_order_page
  - view_order_all_page
  - print_a_paper_inventory
  - perform_an_inventory_count
  - perform_an_inventory_partial_loose_count
  - perform_an_inventory_partial_box_count
  - edit_an_inventory_count
  - oauth_in
  - oauth_out
  - oauth_index
  - oauth_failure
  - oauth_update
  - oauth_delete

## After 1st deploy:
- migrate the dB (which runs the necessary jobs)
- remove extrap models
- remove MaterialsPart model

### Should do:
- easy-print report for setup crew:
  - every component and their subs w/ current counts

- is Oauth Email syncing causing the R14 Memory Quota Exceeded issue?

- Inventory "undo" button? Maybe just for most recent? Or just for @inventory.event_based?

### Someday
1. Ability to pause / cancel registration emails
  - Using a suppress_emails? field?
  - `scope :pre_reminders, -> { where(reminder_sent_at: nil, suppress_reminder_emails: false) }`

2. Inventories#index -> Inventories#history has @item.history_series kickchart, which lays available, box, and loose on the same axis. Should probably not be.
  - Three separate charts, maybe?
  - Three separate axes, but might be confusing: https://www.chartjs.org/docs/latest/axes/
