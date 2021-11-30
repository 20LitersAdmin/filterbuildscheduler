# README
## Slim Down Inventory project

* Run & fix tests
  - Concern test is green
  - Helper test is green
  - Job tests are green
  - Model tests are green
  - Request test is green
  - Service tests are green
  - System tests are red (260 tests , 21 failures, 2 pending)

* New System tests:
  2- combinations_index_page
  2- combinations_show_page
  2- combinations_edit_page
    - create_an_assembly
    - edit_an_assembly
    - destroy_an_assembly

  - component_rails_admin_views
  - component_rails_admin_manage (c, u, di, r, de)

  - donation_list_page_spec

  1- events_lead_page_spec
  - events_rails_admin_views
  - event_rails_admin_discard
  - event_rails_admin_destroy

  - inventory_history_page_spec
  1- inventory_paper_page_spec

  - location_rails_admin_views
  - location_rails_admin_manage (c, u, di, r, de)

  - material_rails_admin_views
  - material_rails_admin_edit (c, u, di, r, de)

  - part_rails_admin_views
  - part_rails_admin_edit (create, update, discard, restore, destroy)

  1- registration_edit_page_spec (with discard and restore and restore_all)
  - registration_rails_admin_views
  - registration_rails_admin_edit (and discard and destroy and restore)
  1- registration_index_page (and resend_all_confirmation_emails)

  - report_page_spec
  - report_volunteer_page_spec
  - report_leader_page_spec

  - supplier_rails_admin_views
  - supplier_rails_admin_manage (c, u, di, r, de)

  - technology_rails_admin_views
  - technology_rails_admin_manage (c, u, di, r, de)

  - user_rails_admin_views
  - user_rails_admin_manage (c, u, di, r, de)
  - user_leaders_page_spec

  - oauth_in
  - oauth_out
  - oauth_index
  - oauth_failure
  - oauth_update
  - oauth_delete

## After 1st deploy:
- Heroku needs redis: https://blog.heroku.com/real_time_rails_implementing_websockets_in_rails_5_with_action_cable#deploying-our-application-to-heroku
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
