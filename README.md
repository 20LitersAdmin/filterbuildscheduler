# README

## Things to do
1. Monthly email isn't sending?

2. Event#show should list private event contact info

3. JQuery registration form validations (use global .has-errors css, see user#edit for good example)

4. Available functions div as partial on more screens (e.g. event/closed, users/communication, events/lead, events/cancelled )

5. View for technology assembly (which items [comps and parts] and #s on hand) -- shows what is needed and how many tech can be built with what's on hand

8. Stats framework (for time period) (visible to Admin)
  - Number of technologies by type
  - Number of vol hours (event length * attendance )
  - Number of volunteers engaged (could be duplicated)
  - Number of events held
  - List of high-participating builders (3+ builds, not leader)
  - List of leaders && participating

## HMMM
1. Inventories created from events aren't subtracting parts from components (parts used to build the technologies_built or boxes_packed)
  - Create a file similar to extrapolate.rb to handle this
2. In the same vain: parts.where(made_from_materials: true) is increased from previous, related materials should decrease fractionally
3. `weeks_to_out` and `per_technology` rely on lots of `.first`s which is an issue for items that `have_many` technologies

## Remind myself:
1. production backup / development restore-from production
2. "Your branch is n commits behind master" - git fetch origin
3. git remote prune origin --dry-run