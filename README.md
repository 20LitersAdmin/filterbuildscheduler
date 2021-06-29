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
  1. Counts are polymorphically joined to an item, including Technology
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
    - run as a Heroku Scheduler function
2. **DONE** `Component.where(completed_tech: true)` are not duplicates of Technology
  - Allow Technologies to be counted
  - Technologies and Components share a master `assemblies` polymorphic join table
    - Make Technologies polymorphically joinable to Assemblies
    - Make Components polymorphically joinable to Assemblies
  - Materials `has_many` Parts

3. Item join tables are simplified
  - dropping 'extrapolate' from all table names
  - following the [naming convention](https://guides.rubyonrails.org/association_basics.html#creating-join-tables-for-has-and-belongs-to-many-associations)
  - removing the following join tables:
    - `extrapolate_technology_parts`
    - `extrapolate_technology_materials`
  - Calculations of distant relations are handled via the existing join tables
    - e.g. "parts per technology": `technology.parts.per_technology`
      - must reach down through technology > components and sum matching parts as discovered, plus any parts directly "assembled" onto that technology

4. Images use an online cloud for storage
  - An S3 bucket exists for storing item images
  - Technologies have 2 images: one for displays, one for inventory
  - Images can be managed through the admin view
    * rails_admin interface for CRUDing photos on items

5. `paranoia` is not a best practice
  - Inventory and Counts do not need to soft-delete
  - Implement [discard](https://github.com/jhawthorn/discard)
  - Figure out if `app/models/concerns/not_deleted.rb` is actually used / useful
  - Remove paranoia from:
    - models
    - database tables
    - rails_admin

6. Items are modified to fit new schema:
  3. change these:
    - delete P111
    - delete anything with '**VWF**'?
    - rename anything with '**20l**'

**Current:**
- `technologies/:id/tree` as a visual of the Assembly tree, with pics!
- NOW: Technology ----> Material: Materials used in a Technology
- I believe migrations are ready for production.
- NEXT: Implement discard

#### After deployment:
* Migrate the db
* `rails_admin` has conflicting `require`s that can't be uncommented until second deploy
* Part's `before_save :set_made_from_materials` can't be uncommented until second deploy

## Remind myself:
3. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`
