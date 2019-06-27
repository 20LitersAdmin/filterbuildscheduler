# README

## Things to do
1. I created EventsController::SubtractSubsets and should write tests for it
  * Test the class (as a model)
  * Write a system test for event-based inventories
  ** The inventory gets counts (EventsController::CountPopulate)
  ** The inventory gets the results added to the apropriate counts (InventoriesController::CountUpdate)
  ** The inventory gets subsets of components subtracted (EventsController::SubtractSubsets)
  ** The inventory gets extrapolations (InventoriesController::Extrapolate)

2. I created financial view and I should write tests for them.

4. Part has_one material (instead of has_many)

5. `events/closed` should be a datatable, not boxes

6. User#show events sections show card views, switch to a table view and make not click-able

7. Stats framework (for time period) (visible to Admin)
  - Number of technologies by type
  - Number of vol hours (event length * attendance )
  - Number of volunteers engaged (could be duplicated)
  - Number of events held
  - List of high-participating builders (3+ builds, not leader)
  - List of leaders && participating

8. SAM3 min orders
9. SAM2 items in dB
10. Check Item Lists against reality

## HMMM
1. `weeks_to_out` and `per_technology` rely on lots of `.first`s which is an issue for items that `have_many` technologies
- Part#technology
- Material#technology
- Component#technologies
2. Tech Status sux big ones and needs some work (the 4-level deep problem)
3. EventsController::SubtractSubsets.subtract! only goes 1 level deep.

## Remind myself:
1. production backup / development restore-from production
  - `User.first.update(password: "password", password_confirmation: "password")`
2. "Your branch is n commits behind master" - git fetch origin
3. git remote prune origin --dry-run
4. `Record.only_deleted.each do |record| record.really_destroy! end`
5. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`


## Data cleanup:
1. Inventory/Parts/Materials/Components data:
- `invs = Inventory.where('date < ?', '2019-01-01')`
- `invs.each { |inv| inv.really_destroy! }`
2. Events/Registrations
3. Users
