# README
## Slim Down Inventory project
### Problems:
1. The Count table grows linearly with every Inventory at a factor of (Component.size + Part.size + Material.size), this takes up a lot of database space unless regularly pruned.
  1. Counts are statically connected to Components, Parts, Materials via optional id attributes
  2. All Counts were created via `InventoriesController::CountCreate` when an inventory is created
    - which copies the values from a previous count
    - Path:
      - `InventoriesController#new` only sets inventory fields
      - then `Inventories#create` triggers `CountCreate.new()` to create all counts
      - then `Inventories#edit` shows all counts
  3. `InventoriesController::update` calls `Receive.new()` to update an item's `last_received_at` and `last_received_quantity`
  4. `InventoriesController::update` calls `Extrapolate.new()` to calculate `count.extrapolated_count`
    - but only on parts?
    - is saved on `Count`, not on the parent item

2. `Component.where(completed_tech: true)` represents a duplication of Technology
  1. Was necessary because counts don't link to Technology

3. Join tables between `Component <=> Part` && `Part <=> Material` are duplicative of join tables between `Technology <=> Part` && `Technology <=> Material`
    1. Was necessary for faster, easier calculation of "parts per technology" and "materials per technology"

4. Images are soft-coded to Components, Parts and Materials based on UID, which is static, not dynamic

### Solutions:
1. Count records are temporary records, created when an inventory is created and destroyed after their meaningful values are transferred to their corresponding Materials, Parts, Components, and Technologies
  1. **DONE** Counts are polymorphically joined to an item, including Technology

    - forms, params, and controllers will need to be adjusted

  2. **NOPE** Counts are created based on items, dynamically created when an inventory is created

  3. `Receive.new()` function is handled by a job that runs after inventory is finalized

  4. Calculating `count.extrapolated_count` is depreciated

  5. Count records can still track partial counts (loose items vs. boxed items), and record which User submitted the Count
    - **DONE** but the 'partial' interface has a better UX
    - remove all Count methods, scopes, and item relationships except:
      - `count.link_text`
      - `count.link_class`
      - `count.sort_by_user`
  6. **DONE** Count-related fields are added to Material, Part, Component, and Technology:
    - **DONE** Three `integer` attributes for current counts:
      - `[ loose | box | available ]`
        - availabe == loose + (box * quantity_per_box)
    - **DONE** One `jsonb` for history:
      - `{ inventory_id: { loose: #, box: #, total: # } }`
    - **DONE** One `jsonb` for quantities:
      - `{ UID: quantity_per_technology}`
        - updated whenever an Assembly or MaterialsPart is saved/destroyed
    - https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb
  7. A job handles transferring count-related fields to it's related item, then deletes the Count record.
    - The job runs `count.update_item_and_destroy!`
    - The job runs after Inventory is marked completed via `Delayed::Job#perform_later`
    - Should Counts persist for one cycle? Meaning, delete the `Inventory.former`'s counts when a new inventory is created?

2. **DONE** `Component.where(completed_tech: true)` are not duplicates of Technology
  - **DONE** Allow Technologies to be counted
  - **DONE** Technologies, Components, and Parts share a master `assemblies` polymorphic join table
  - **DONE** Materials `has_many` Parts

3. Item join tables are simplified
  - **DONE** dropping 'extrapolate' from all table names
  - **DONE** following the naming convention
  -  removing the following join tables:
    - `extrapolate_technology_parts`
    - `extrapolate_technology_materials`
  - **YAGNI** Calculations of distant relations are handled via the existing join tables
    - **DONE** Quantity and depth calculations are handled via `QuantityAndDepthCalculationJob`
    - **DONE** Price calculation is handled via `PriceCalculationJob`

4. Images use an online cloud for storage
  - **DONE** An S3 bucket exists for storing item images
  - **DONE** Technologies have 2 images: one for displays, one for inventory
  - **DONE** Locations have an image
  - Images can be managed through the admin view
    * rails_admin [interface for management](https://github.com/sferik/rails_admin/wiki/ActiveStorage)
  - **DONE** Images are automatically migrated via `ImageSyncJob.perform_now`

5. **DONE** `paranoia` is not a best practice
  - **DONE** Inventory and Counts do not need to soft-delete
  - **DONE** Implement [discard](https://github.com/jhawthorn/discard)
  - **DONE** Figure out if `app/models/concerns/not_deleted.rb` is actually used / useful
  - Remove paranoia from:
    - **DONE** models
    - **DONE** database tables
    - **DONE** rails_admin

6. **DONE** Items are modified to fit new schema:
  1. unify anything with '**VWF**' and '**20l**'


### Nerfed pages:
* status_inventories_path
* financials_inventories_path
* Inventory#show - is it worth having?
* Inventories#status - still relies on counts && primary components
* `/admin/event&scope=closed` vs. `/events/closed`
* `Events#cancelled` - relies on `.only_deleted`
  - vs. `/admin/event&scope=discarded`


### Current:
1. Count records are temporary records, created when an inventory is created and destroyed after their meaningful values are transferred to their corresponding Materials, Parts, Components, and Technologies

  1. `counts/_edit` is a shit show of nested ifs
    - item.only_loose doesn't need "Submit Loose Count" button, only "Submit"
    - when @count.partial_box? or @count.partial_loose? the opposite submit partial button shouldn't be visible

  3. When finalizing inventory (InventoriesController#update), CountTransfer runs
    - copies all counts.changed to their items
    - deletes all counts

  4. Calculating count.extrapolated_count is depreciated

  5. Events create inventories when they have results. See:
    - EventsController::CountPopulate
    - EventsController::CreateInventory
    - EventsController::SubtractSubsets


### Still to do:
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

- Calculate how many more items can be made:
  - Parts.where(made_from_materials: true)
  - Components
  - Technologies

- remove `_event_functions.html.erb` && calls to this partial
  - Leaders should be able to get to `events/lead` without having to visit `rails_admin`

- Events
  - EventsController ln 28: `technology.img_url`
  - probably a few `event.img_url` hanging out there as well

- RailsAdmin:
  - CRUD OauthUsers?
  - CRUD Emails?
    - is Oauth Email syncing causing the R14 Memory Quota Exceeded issue?
  - CRUD Organizations?

## After 1st deploy:
- migrate the dB (which runs the necessary jobs)


## Remind myself:
3. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`

# Never trigger an analyzer when calling methods on ActiveStorage
# ActiveStorage::Blob::Analyzable.module_eval do
#   def analyze_later; end

#   def analyzed?
#     true
#   end
# end
