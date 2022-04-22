# README
## MailerLite integration:
- Kindful's contact/query "has_email": "Yes" returns all records
- Kindful's contact/query "linked" returns none currently
  - Linking records could be beneficial for tracking new and changed: https://developer.kindful.com/customer/linking-guide/contact-link
  - But linking would require a dB table with at least [id, external_id] fields
    - and have a max of 5,000 rows
- MailerLite has s Ruby gem: https://github.com/jpalumickas/mailerlite-ruby
- MailerLite reference: https://developers.mailerlite.com/reference
- MailerLite API rate limit: 60 requests per endpoint per minute max

### Contacts/Subscribers:
  _no Kindful webhooks exist for Contact changes, so these must be done as queries_
  - Kindful Contacts that have been created: "not_linked"
    _create a MailerLite subscriber_
  - Kindful Contacts that have been updated: "linked", "changed"
    - email, email_opt_out, alt_email
    _a MailerLite subscriber is updated
  - Kindful COntacts that have been archived: (part of "linked", "changed"?)
    _a MailerLite subscriber is destroyed?_

  _MailerLite has webhooks on Subscriber and Campaign
  - When a MailerLite record is created
    - via sign-up form on webiste?
    _a new Kindful contact is created_
  - When a MailerLite record changes
    - via "manage preferences" from email?
    - via "unsubscribe" request
    _a Kindful contact is updated_

### Kindful Notes:
  - MailerLite read receipts
    - as a daily cron job
    - will need to identify new opens, reads, clicks on existing campaigns (and ignore existing)


##### --- older notes ---

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

## Issues:
- Shipping inventory, when submitting positive numbers doesn't submit, but also doesn't display an error.
- Technology.list_worthy is broad and sucks. e.g. Technology.last

### Policies:
- Prevent some user types from accessing some parts of rails_admin?

- Rails_admin#user#edit
  - prevent some fields from being visible based on user type?
    - only admins can create admins

- Rails_admin#destroyable
  - only available to full admins?

- User.non_builders scope is missing new roles

### Should do:
- Assembly: edit: affects_price_only boolean

- rails_admin pjax screws up browser back and forward buttons

- paper inventory should sort
  - by tech, and traverse up tree for each tech
  - Alphabetical by UID or name

- easy-print report for setup crew:
  - select a single tech (99% its SAM3, once every 18 months it'll be RWHS, MOF or Handpump)
  - every component and their subs w/ current counts

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
