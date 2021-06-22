# README
## Slim Down Inventory project
### Problems:
1. The Count table grows linearly with every Inventory at a factor of (Component.size + Part.size + Material.size), this takes up a lot of database space unless regularly pruned.

2. `Component.where(completed_tech: true)` represents a duplication of Technology
  1. Was necessary because counts don't link to Technology
  2. Counts are statically connected to Components, Parts, Materials via optional id attributes
3. Join tables between `Component <=> Part` && `Part <=> Material` are duplicative of join tables between `Technology <=> Part` && `Technology <=> Material`
    1. Was necessary for faster, easier calculation of "parts per technology" and "materials per technology"
4. Images are soft-coded to Components, Parts and Materials based on UID, which is static, not dynamic
5. `part.made_from_materials?` and any join table record with `part_id` is duplicative (currently not fixed)

### Solutions:
1. Count records are temporary records, created when an inventory is created and destroyed after their meaningful values are transferred to their corresponding Materials, Parts, Components, Assemblies and Technologies
  - Count records can still track partial counts (loose items vs. boxed items), and record which User submitted the Count
    - but the 'partial' interface should have better UX
    - remove all Count methods, scopes, and item relationships except:
      - `count.link_text`
      - `count.link_class`
      - `count.sort_by_user`
  - Count-related fields are added to Material, Part, Component, Assembly and Technology:
    - **DECIDE ON THIS: Four `integer` attributes for current counts:**
      - `[ loose | box | total | available ]`
      - availabe == loose + (box x quantity_per_box)
      - total == available + "sum of items in parents"
    - **DECIDE ON THIS: One `jsonb` for history:**
      - `{ inventory_id: #, counts: { loose: #, box: #, total: # } }`
  - Counts are polymorphically joined to an item, including Technology
    - forms, params, and controllers will need to be adjusted
    - **solves # 2.1 & 2.2**
  - A job handles transferring count-related fields to it's related item, then deletes the Count record.
    - The job runs `count.update_item_and_destroy!`
    - run as a Heroku Scheduler function
2. Un-duplicate Components:
  - Allow Technologies to be Counted
  - Add Assemblies as an intermediary layer
    - Technologies `has_many :through` Assemblies
    - Assemblies `has_many :through` Components and Parts
      - polymorphic join table: [ assembly_id | item_type | item_id ] where item type is limited to 'Component' || 'Part'
    - temporary `component.make_into_assembly_and_destroy!` method to make migration easier
  - Components `has_many :through` Parts
  - Materials `has_many :through` Parts
3. Item join tables are simplified
  - dropping 'extrapolate' from all table names
  - following the [naming convention](https://guides.rubyonrails.org/association_basics.html#creating-join-tables-for-has-and-belongs-to-many-associations)
  - removing the following join tables:
    - `extrapolate_technology_parts`
    - `extrapolate_technology_materials`
  - Calculations of distant relations are handled via the existing join tables
    - **solves 3.1**
    - e.g. "parts per technology": `technology.parts.per_technology`
      - must reach down through technology > assemblies > components and sum matching parts as discovered
    - distant relations to calculate:
      - "components per technology" (through Assembly)
      - "parts per technology" (through Assembly && Component)
      - "materials per technology" (will be fractional) (through Assembly && Component && Part)
      - "parts per assembly" (through Component)
      - "materials per assembly" (through Component && Part)
4. Images use an S3 bucket for storage
  - Technologies have 2 images: one for displays, one for inventory
  - Images can be managed through the admin view
    * rails_admin interface for CRUDing photos on items





## Remind myself:
1. production backup / development restore-from production
  - `User.first.reset_password("password", "password")`
2. `Record.only_deleted.each do |record| record.really_destroy! end`
3. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`
