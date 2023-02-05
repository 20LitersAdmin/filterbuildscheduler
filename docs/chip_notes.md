## Bloomerang client
# TODO: Re-send Stripe webhooks since Feb 1st-ish (check with Amanda for what she's hand-migrated)

## Admin can't register new user when event is full

## Inventory:
- Receiving inventory:
  - should only generate counts for Materials and Parts.not_made_from_materials
  - should include Materials/Parts not associated with any technology

## Assemblies:
- SAM3 and boxes: requires an assembly to have floats

## Donation list
- Total cost is wrong?
- Filtering items: SAM2 only returns two materials and nothing else?

## Setup Crew:
- System has a system test for generating SetupMailer.notify
  - from EventsController#Setup (only for self)
  - from SetupsController#edit (only new users)
  - from SetupsController#new (as admin vs setup_crew)
- System has a test for SetupMailer.notify
- System has a test for SetupMailer.remind
  - including a timing test (2 days in the future)
- System has a test for SetupReminderJob

- volunteer report: include event setups with a standard hour setting (e.g 1.5 hours)


### Policies:
- Prevent some user types from accessing some parts of rails_admin?

- Rails_admin#user#edit
  - prevent some fields from being visible based on user type?
    - only admins can create admins

- Rails_admin#destroyable
  - only available to full admins?

- User.non_builders scope is missing new roles

### Should do:
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

### Someday
1. Ability to pause / cancel registration emails
  - Using a suppress_emails? field?
  - `scope :pre_reminders, -> { where(reminder_sent_at: nil, suppress_reminder_emails: false) }`


### system spec policy checking:
```
context 'when visited by a' do
  it 'anon user, it redirects to sign-in page' do
    visit url

    expect(page).to have_content 'You need to sign in first'
    expect(page).to have_content 'Sign in'
  end

  it 'builder, it redirects to home page' do
    sign_in create :user
    visit url

    expect(page).to have_content 'You don\'t have permission'
    expect(page).to have_content 'Upcoming Builds'
  end

  it 'leader, it redirects to home page' do
    sign_in create :leader
    visit url

    expect(page).to have_content 'You don\'t have permission'
    expect(page).to have_content 'Upcoming Builds'
  end

  it 'inventoryist, it shows the page' do
    sign_in create :inventoryist
    visit url

    expect(page).to have_content 'Something'
  end

  it 'scheduler, it redirects to home page' do
    sign_in create :scheduler
    visit url

    expect(page).to have_content 'You don\'t have permission'
    expect(page).to have_content 'Upcoming Builds'
  end

  it 'data_manager, it shows the page' do
    sign_in create :data_manager
    visit url

    expect(page).to have_content 'Something'
  end

  it 'admin, it shows the page' do
    sign_in create :admin
    visit url

    expect(page).to have_content 'Something'
  end
end
```
