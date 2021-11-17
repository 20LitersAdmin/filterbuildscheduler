# README
## Slim Down Inventory project
* Search for .deleted_at, .really_delete
* Run & fix tests

### Nerfed pages:
* `_*_functions` - how many can be removed?
  - Leaders should be able to get to `/events/lead` without having to visit `rails_admin`
  - Scheduler should be able to get to `/leaders` and `/events/lead` without having to visit `rails_admin`
  - Data Manager should be able to get to `users/communications` VIA `rails_admin`


### Still to do:
- easy-print report for setup crew:
  - every component and their subs w/ current counts

- is Oauth Email syncing causing the R14 Memory Quota Exceeded issue?

- Inventory "undo" button? Maybe just for most recent? Or just for @inventory.event_based?

### And also!
1. Ability to pause / cancel registration emails
  - Using a suppress_emails? field?
  - `scope :pre_reminders, -> { where(reminder_sent_at: nil, suppress_reminder_emails: false) }`

2. Inventories#index -> Inventories#History has @item.history_series kickchart, which lays available, box, and loose on the same axis. Should probably not be.
  - Three separate charts, maybe?
  - Three separate axes, but might be confusing: https://www.chartjs.org/docs/latest/axes/

3. Simple-form client-side validations: https://jarlowrey.com/blog/simple-forms-client-validation-rails-5.html
- yeah, but for what forms? Inventory? Event creation?

## After 1st deploy:
- migrate the dB (which runs the necessary jobs)
- remove extrap models
- remove MaterialsPart

## Remind myself:
`orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`
