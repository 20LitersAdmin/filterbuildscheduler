# Chip's notes

## As of Apr 2023
- receiving inventories have no history?
- receiving inventories are failing?
- event inventories: check around 4/6 and 4/12
- loose counts are negative due to event inventory?

## Admin can't register new user when event is full

## Inventory

- Receiving inventory:
  - should only generate counts for Materials and Parts.not_made_from_materials
  - should include Materials/Parts not associated with any technology

## Assemblies

- SAM3 and boxes: requires an assembly to have floats

## Donation list

- Total cost is wrong?
- Filtering items: SAM2 only returns two materials and nothing else?

## Setup Crew

- System has a system test for generating SetupMailer.notify
  - from EventsController#Setup (only for self)
  - from SetupsController#edit (only new users)
  - from SetupsController#new (as admin vs setup_crew)
- System has a test for SetupMailer.notify
- System has a test for SetupMailer.remind
  - including a timing test (2 days in the future)
- System has a test for SetupReminderJob

- volunteer report: include event setups with a standard hour setting (e.g 1.5 hours)

## Policies

- Prevent some user types from accessing some parts of rails_admin?

- Rails_admin#user#edit

  - prevent some fields from being visible based on user type?
    - only admins can create admins

- Rails_admin#destroyable

  - only available to full admins?

- User.non_builders scope is missing new roles

## Should do

- rails_admin pjax screws up browser back and forward buttons

- Inventory "undo" button? Maybe just for most recent? Or just for @inventory.event_based?

- more System tests:

  - component_rails_admin_views
  - component_rails_admin_manage (c, u, di, r, de)

  - donation_list_page_spec

  - events_rails_admin_views
  - event_rails_admin_discard
  - event_rails_admin_destroy

  - inventory_history_page_spec

  - location_rails_admin_views
  - location_rails_admin_manage (c, u, di, r, de)

  - material_rails_admin_views
  - material_rails_admin_edit (c, u, di, r, de)

  - part_rails_admin_views
  - part_rails_admin_edit (create, update, discard, restore, destroy)

  - registration_rails_admin_views
  - registration_rails_admin_edit (and discard and destroy and restore)

  - report_page_spec
  - report_volunteer_page_spec
  - report_leader_page_spec

  - supplier_rails_admin_views
  - supplier_rails_admin_manage (c, u, di, r, de)

  - technology_rails_admin_views
  - technology_rails_admin_manage (c, u, di, r)

  - user_rails_admin_views
  - user_rails_admin_manage (c, u, di, r, de)
  - user_leaders_page_spec

  - oauth_in
  - oauth_out
  - oauth_index
  - oauth_failure
  - oauth_update
  - oauth_delete

## Someday

- Ability to pause / cancel registration emails
  - Using a suppress_emails? field?
  - `scope :pre_reminders, -> { where(reminder_sent_at: nil, suppress_reminder_emails: false) }`


## Errors
```sh
Finished in 2 minutes 40 seconds (files took 3.2 seconds to load)
1054 examples, 27 failures, 2 pending

Failed examples:

rspec ./spec/system/user_communication_preferences_spec.rb:86 # Users#communication page allows for remotely updating user.email_opt_out records
rspec ./spec/system/user_communication_preferences_spec.rb:77 # Users#communication page allows for searching for a user
rspec ./spec/system/event_sharing_spec.rb:47 # An event can be shared by printing a poster
rspec ./spec/system/event_sharing_spec.rb:58 # An event can be shared by copying the URL
rspec ./spec/system/event_sharing_spec.rb:15 # An event can be shared on facebook
rspec ./spec/system/event_sharing_spec.rb:32 # An event can be shared on twitter
rspec ./spec/system/event_sharing_spec.rb:11 # An event can be shared from the event's show page
rspec ./spec/system/event_sharing_spec.rb:65 # An event can be shared unless the event is in the past then the buttons are not present
rspec ./spec/system/info_page_spec.rb:10 # Info page can be visited
rspec ./spec/system/info_page_spec.rb:15 # Info page accordion div can be clicked
rspec ./spec/system/event_edit_page_with_report_spec.rb:195 # To create an event report fill out the form and submit it without sending emails
rspec ./spec/system/event_edit_page_with_report_spec.rb:215 # To create an event report fill out the form and submit it while sending emails
rspec ./spec/system/event_edit_page_with_report_spec.rb:252 # To create an event report fill out the form and submit it to send registration information to Bloomerang
rspec ./spec/system/event_edit_page_with_report_spec.rb:163 # To create an event report fill out the form with attendee information auto-counts the total attendance
rspec ./spec/system/event_edit_page_with_report_spec.rb:181 # To create an event report fill out the form with attendee information  allows for select-all / un-select all
rspec ./spec/system/combination_edit_page_spec.rb:115 # Combinations#edit allows an authorized user to delete an assembly
rspec ./spec/system/combination_edit_page_spec.rb:99 # Combinations#edit allows an authorized user to edit an assembly
rspec ./spec/system/combination_edit_page_spec.rb:73 # Combinations#edit allows an authorized user to create an assembly
rspec ./spec/system/event_edit_page_spec.rb:124 # Event edit page allows for replicating
rspec ./spec/system/inventory_order_all_page_spec.rb:92 # Order all supplies page shows items that can be ordered by supplier
rspec ./spec/system/inventory_order_all_page_spec.rb:87 # Order all supplies page shows items that can be ordered in a single table
rspec ./spec/system/inventory_order_page_spec.rb:87 # Order supplies page shows items that need to be ordered in a single table
rspec ./spec/system/inventory_order_page_spec.rb:92 # Order supplies page shows items that need to be ordered by supplier
rspec ./spec/system/inventory_edit_page_spec.rb:178 # Inventory edit page when counting items, users can submit counts
rspec ./spec/system/inventory_edit_page_spec.rb:142 # Inventory edit page when counting items, users can filter by status
rspec ./spec/system/inventory_edit_page_spec.rb:120 # Inventory edit page when counting items, users can search
rspec ./spec/system/inventory_edit_page_spec.rb:217 # Inventory edit page when counting items, users can finalize the inventory
```

## May 2024 Fixes
- Add Rollbar
- Add buttons for manually syncing Bloomerang Constituents
