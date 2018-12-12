# README

## Things to do
1. I re-built Inventory submission:
  * Test a manual inventory
  * Test a receiving inventory
  * Test a shipping inventory
  * Test an event inventory

2. I added / changed methods to Count#
  * #diff_from_previous(field)
  * #previous_inventory
  * #previous_count
  * #previous_loose
  * #previous_box

2. I created EventsController::SubtractSubsets and should write tests for it
  * Test the class (as a model)
  * Write a system test for event-based inventories
  ** The inventory gets counts (EventsController::CountPopulate)
  ** The inventory gets the results added to the apropriate counts (InventoriesController::CountUpdate)
  ** The inventory gets subsets of components subtracted (EventsController::SubtractSubsets)
  ** The inventory gets extrapolations (InventoriesController::Extrapolate)

3. JQuery registration form validations (use global .has-errors css, see user#edit for good example)

4. Part / Material / Component history view, Tech name links to this from Tech Status page.

5. inv/status - relies on finalized inventory.

7. Integrate partial buttons into navbar as sub-items (inv and builds) - make navbar sticky?

8. SAM3 min orders 

9. Stats framework (for time period) (visible to Admin)
  - Number of technologies by type
  - Number of vol hours (event length * attendance )
  - Number of volunteers engaged (could be duplicated)
  - Number of events held
  - List of high-participating builders (3+ builds, not leader)
  - List of leaders && participating

10. /events/lead -- SHOW TECHNOLOGY

## HMMM
1. Inventories created from events aren't subtracting parts from components (parts used to build the technologies_built or boxes_packed)
  - Create a file similar to extrapolate.rb to handle this
2. In the same vain: parts.where(made_from_materials: true) is increased from previous, related materials should decrease fractionally
3. `weeks_to_out` and `per_technology` rely on lots of `.first`s which is an issue for items that `have_many` technologies

## Remind myself:
1. production backup / development restore-from production
  - User.all.each do |u| u.update(password: "password", password_confirmation: "password") end
2. "Your branch is n commits behind master" - git fetch origin
3. git remote prune origin --dry-run