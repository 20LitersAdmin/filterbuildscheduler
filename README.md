# README

## Things to do
0. Accept button on registration modal not working
0.1 Registration form with errors - form fields aren't persistent
0.2 Modal page when form with errors doesn't close
0.3 Jeff --> Jereme, Dannie, Natalie
0.4 "Open Builds" partial should link to edit_event_path


0.5 "Email has already been taken" - events/#id/register && events/#id (not logged in)

0.6 Get rid of table head scrolling issue

1. Replicate function - GMT issue??

1.A - Edit registration needs email opt out

2. I created EventsController::SubtractSubsets and should write tests for it
  * Test the class (as a model)
  * Write a system test for event-based inventories
  ** The inventory gets counts (EventsController::CountPopulate)
  ** The inventory gets the results added to the apropriate counts (InventoriesController::CountUpdate)
  ** The inventory gets subsets of components subtracted (EventsController::SubtractSubsets)
  ** The inventory gets extrapolations (InventoriesController::Extrapolate)

3. Notify us if someone important in Kindful registers for an event
- https://developer.kindful.com/customer/querying-guide/contact-queries#retrieve
- Managed donor group: 26572
- If yes, send an email to Amanda & Chip with a calendar appointment for the event.

4. Part has_one material (instead of has_many)

5. Inventory#create: ability to mark some technologies as "unchanged" which would auto-carry the previous value and mark them as counted.

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
1. Inventory data:
- `invs = Inventory.where('date < ?', '2019-11-01')`
- `invs.each { |inv| inv.really_destroy! }`
2. Parts/Materials/Components (dependent: :destroy):
- `mats = Material.only_deleted`
- `mats.each { |m| m.really_destroy! }`
3. Events/Registrations
4. Users
5. Delayed::Job:
- `production run rails jobs:clear`
