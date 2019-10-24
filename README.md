# README

## Things to do
1. I created EventsController::SubtractSubsets and should write tests for it
  * Test the class (as a model)
  * Write a system test for event-based inventories
  ** The inventory gets counts (EventsController::CountPopulate)
  ** The inventory gets the results added to the apropriate counts (InventoriesController::CountUpdate)
  ** The inventory gets subsets of components subtracted (EventsController::SubtractSubsets)
  ** The inventory gets extrapolations (InventoriesController::Extrapolate)

3. Ability to create multiple events at once: Replicator.rb
  - reset dev database
  - test skips duplicate first event (if dates are not changed)
  - test emails using Foreman
  - switch back to #Mailer.delay.#method() before deployment

4. Part has_one material (instead of has_many)

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
