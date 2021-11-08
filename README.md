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
* InventoriesController#order_all
* InventoriesController#order

### Nerfed pages:
* status_inventories_path
* financials_inventories_path

* Inventories#status - still relies on counts && primary components
* `/admin/event&scope=closed` vs. `/events/closed`
* `Events#cancelled` - relies on `.only_deleted`
  - vs. `/admin/event&scope=discarded`

### Still to do:
- easy-print report for setup crew:
  - every component and their subs w/ current counts

- PriceCalculationJob: Make sure `Part#made_from_material` gets their prices set before looping over assemblies.

- `Component#weeks_to_out` should traverse downward
  - Or YAGNI weeks_to_out all together

- remove `_event_functions.html.erb` && calls to this partial
  - Leaders should be able to get to `/events/lead` without having to visit `rails_admin`
  - Scheduler should be able to get to `/leaders` and `/events/lead` without having to visit `rails_admin`

- probably a few `event.img_url` hanging out there as well
- technology.description being used for label? Should be one text field for EventsController#show and one for labels

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

## Remind myself:
`orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`

# Never trigger an analyzer when calling methods on ActiveStorage
# ActiveStorage::Blob::Analyzable.module_eval do
#   def analyze_later; end

#   def analyzed?
#     true
#   end
# end
