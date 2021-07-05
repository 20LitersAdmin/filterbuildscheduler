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

5. `part.made_from_materials?` and any join table record with `part_id` is duplicative (currently not fixed)

### Solutions:
1. Count records are temporary records, created when an inventory is created and destroyed after their meaningful values are transferred to their corresponding Materials, Parts, Components, and Technologies
  1. **DONE** Counts are polymorphically joined to an item, including Technology
    - forms, params, and controllers will need to be adjusted
  2. Counts are created based on items, not dynamically created when an inventory is created.
    - Path:
      - `InventoriesController#new` only sets inventory fields
      - then `Inventories#create` fires
      - then `Inventories#edit` shows all items in an ActiveRecord collection
      - clicking a button on an item displays a count form, which AJAXes a count into existence
  3. `Receive.new()` function is handled by a job that runs after inventory is finalized
  4. Calculating `count.extrapolated_count` is depreciated

  5. Count records can still track partial counts (loose items vs. boxed items), and record which User submitted the Count
    - but the 'partial' interface has a better UX
    - remove all Count methods, scopes, and item relationships except:
      - `count.link_text`
      - `count.link_class`
      - `count.sort_by_user`
  6. **DONE** Count-related fields are added to Material, Part, Component, and Technology:
    - Three `integer` attributes for current counts:
      - `[ loose | box | available ]`
        - availabe == loose + (box * quantity_per_box)
    - One `jsonb` for history:
      - `{ inventory_id: { loose: #, box: #, total: # } }`
  7. A job handles transferring count-related fields to it's related item, then deletes the Count record.
    - The job runs `count.update_item_and_destroy!`
    - The job runs after Inventory is marked completed via DelayedJob `perform_later`
2. **DONE** `Component.where(completed_tech: true)` are not duplicates of Technology
  - **DONE** Allow Technologies to be counted
  - **DONE** Technologies, Components, and Parts share a master `assemblies` polymorphic join table
  - **DONE** Materials `has_many` Parts

3. Item join tables are simplified
  - **DONE** dropping 'extrapolate' from all table names
  - **DONE** following the [naming convention](https://guides.rubyonrails.org/association_basics.html#creating-join-tables-for-has-and-belongs-to-many-associations)
  - **DONE** removing the following join tables:
    - `extrapolate_technology_parts`
    - `extrapolate_technology_materials`
  - Calculations of distant relations are handled via the existing join tables
    - e.g. "parts per technology": `technology.parts.per_technology`
      - must reach down through technology > components and sum matching parts as discovered, plus any parts directly "assembled" onto that technology
    - best idea so far: traverse down and up to find common parents & children
      - `technology.components_per_technology(part)`
      - `technology.parts_per_technology(part)`
      - `technology.materials_per_technology(part)`
    - YAGNI validation:
      - Bill of Materials / pick sheet
      - Price calculation might be faster via BoM than via total tree traversal

4. Images use an online cloud for storage
  - **DONE** An S3 bucket exists for storing item images
  - **DONE** Technologies have 2 images: one for displays, one for inventory
  - **DONE** Locations have an image
  - Images can be managed through the admin view
    * rails_admin [interface for management](https://github.com/sferik/rails_admin/wiki/ActiveStorage)

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

### Stretch goals:
7. HAML > .html.erb
  - install HAML and use for all new/updated views
  - slowly migrate away from .html.erb via file replacement over time

8. Inventory#edit uses Websockets for real-time page changes when multiple users are performing an inventory at once.

**Current:**
- `technologies/:id/tree` as a visual of the Assembly tree, with pics!
- NEXT: Re-build `TechnologyController#items`
- NEXT: MaterialsPart allows for duplicates. Prevent this.
- NEXT: Inventory flow && Count creation

#### After 1st deployment:
* Migrate the db

#### 2nd deployment work to be done
* Un-comment-out `Part#before_save :set_made_from_materials`
* Remove TEMP methods from Part, Component, Material
* Delete Extrap models
* Un-comment-out `has_one_attached` on Items
* Un-comment-out `include Discard::Model` && `scoe :active` on Models
* Remove `paranoia` gem
* Delete all commented relations on Models
* Un-do Paranoia -> Discard patching
  -  `EventsController#398`
  -


#### 3rd deployment work to be done:
* Run `ImageSyncJob.perform_now` in production (now that Items `has_one_attached`)
* Fix RailsAdmin, which will be pretty nerfed from 1st deploy
* Remove assets.rb#12


### 4th deployment work to be done:
* Drop `Technology.img_url`
* Drop `Location.photo_url`
* Remove UIDS folder


## Remind myself:
3. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`

# Never trigger an analyzer when calling methods on ActiveStorage
# ActiveStorage::Blob::Analyzable.module_eval do
#   def analyze_later; end

#   def analyzed?
#     true
#   end
# end
