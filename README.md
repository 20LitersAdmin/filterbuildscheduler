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


### Nerfed pages:
* status_inventories_path
* financials_inventories_path
* Inventory#index when the latest inventory has counts
  - Remove "View" button (as there is no Inventor#show), or make Admin only if "undo"

* Inventories#status - still relies on counts && primary components
* `/admin/event&scope=closed` vs. `/events/closed`
* `Events#cancelled` - relies on `.only_deleted`
  - vs. `/admin/event&scope=discarded`

### Current:
* InventoriesController#paper - should probably be CombinationsController instead
  - because it's a collection of items now, not counts
* You can NO LONGER "unlock" an inventory because there are no count records left
* Inventory#show - is it worth having?
  - probably, with @inventory.history loop
  - AND ability to "undo" an inventory (e.g. an Event inventory that just makes everything suck)

### Still to do:

- Item#produceable: what is it's value?
  - For Filter Build leaders to know what *should* be produceable based upon inventory

- Inventories#index -> Inventories#History has @item.history_series kickchart, which lays available, box, and loose on the same axis. Should probably not be.
  - Three separate charts, maybe?
  - Three separate axes, but might be confusing: https://www.chartjs.org/docs/latest/axes/

- ComponentsController#order && ComponentsController#order_low
  - from InventoriesController#order_all and InventoriesController#order

- What happens when a price is changed?
  - Material
  - Part
  - Component
  - Technology

- Make sure `Part#not_made_from_materials` and `Material#all`price is being escalated to assemblies on save
  - Right now, saving an Assembly trigers PriceCalculationJob, but what if you change the price of a Part or Material? That needs to cascade up.
  - Assemblies have a price (item.price * quantity)

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

3. Simple-form client-side validations: https://jarlowrey.com/blog/simple-forms-client-validation-rails-5.html
- yeah, but for what forms? Inventory? Event creation?

## After 1st deploy:
- migrate the dB (which runs the necessary jobs)
- remove extrap models

## Remind myself:
3. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`

# Never trigger an analyzer when calling methods on ActiveStorage
# ActiveStorage::Blob::Analyzable.module_eval do
#   def analyze_later; end

#   def analyzed?
#     true
#   end
# end
