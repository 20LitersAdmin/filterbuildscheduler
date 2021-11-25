# README
## Slim Down Inventory project

* Run & fix tests
* New tests:
  - System: Rails Admin custom actions
  - System: Combinations functions
  - System: Event replication (with JS for event dates)
  - System: Event duplication
  - System: Inventory counting (with ActionCable)
  - System: Report pages
  - System: view donation list
  - System: Inventory history
  - System: Inventory paper
  - System: Oauth in
  - System: Oauth out
  - System: Oauth index
  - System: Oauth failure
  - System: Oauth update
  - System: Oauth delete
  - Jobs:
    - RegistrationReminder
  - Concern: Itemable


## After 1st deploy:
- migrate the dB (which runs the necessary jobs)
- remove extrap models
- remove MaterialsPart

### Should do:
- easy-print report for setup crew:
  - every component and their subs w/ current counts

- is Oauth Email syncing causing the R14 Memory Quota Exceeded issue?

- Inventory "undo" button? Maybe just for most recent? Or just for @inventory.event_based?

### Someday
1. Ability to pause / cancel registration emails
  - Using a suppress_emails? field?
  - `scope :pre_reminders, -> { where(reminder_sent_at: nil, suppress_reminder_emails: false) }`

2. Inventories#index -> Inventories#History has @item.history_series kickchart, which lays available, box, and loose on the same axis. Should probably not be.
  - Three separate charts, maybe?
  - Three separate axes, but might be confusing: https://www.chartjs.org/docs/latest/axes/

3. Simple-form client-side validations: https://jarlowrey.com/blog/simple-forms-client-validation-rails-5.html
- yeah, but for what forms? Inventory? Event creation?

