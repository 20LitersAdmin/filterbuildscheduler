# README
## Slim Down Inventory project

5. Count records can still track partial counts (loose items vs. boxed items), and record which User submitted the Count
  - **DONE** but the 'partial' interface has a better UX
  - remove all Count methods, scopes, and item relationships except:
    - `count.link_text`
    - `count.link_class`
    - `count.sort_by_user`

4. Images use an online cloud for storage
  - **DONE** An S3 bucket exists for storing item images
  - **DONE** Technologies have 2 images: one for displays, one for inventory
  - **DONE** Locations have an image
  - Images can be managed through the admin view
    * rails_admin [interface for management](https://github.com/sferik/rails_admin/wiki/ActiveStorage)
  - **DONE** Images are automatically migrated via `ImageSyncJob.perform_now`

### Current:

* Actually, should Registrations be Discardable?
  - Event is cancelled (discarded)
    - should discard Registrations as well
  - Event is restored
    - should restore Registrations as well
  - Event is destroyed for real via `rails_admin`
  - Event
  - Registrations should delete by default as a user action
    - Registration is cancelled (deleted) via user: using email link with email and token
    - Registration is cancelled (deleted) via admin: via event/:id/registrations


* Events#closed should be replaced by `/admin/event?model_name=event&scope=closed`
* Events#cancelled should be replaced by `/admin/event?model_name=event&scope=discarded`

* Itemable things need `.kept` in lots of places
  - Checked all controllers
* `.restore` => `.undiscard`
* Start searching for # TODO:
* Run & fix tests

* `registration.non_leaders` => `registration.builders`
* `registration.non_leaders_registered()` => `registration.builders_registered`


### Nerfed pages:
* `_*_functions` - how many can be removed?
  - Leaders should be able to get to `/events/lead` without having to visit `rails_admin`
  - Scheduler should be able to get to `/leaders` and `/events/lead` without having to visit `rails_admin`
  - Data Manager should be able to get to `users/communications` VIA `rails_admin`


### Still to do:
- easy-print report for setup crew:
  - every component and their subs w/ current counts

- Weeks_to_out
  - `Component#weeks_to_out` should traverse downward
    - Or YAGNI weeks_to_out all together

- is Oauth Email syncing causing the R14 Memory Quota Exceeded issue?

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
