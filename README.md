# README

## Things to do
3. JQuery registration form validations (use global .has-errors css, see user#edit for good example)

4. Part / Material / Component history view, Tech name links to this from Tech Status page.

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
  - User.all.each do |u| u.update(password: "password", password_confirmation: "password") end
2. "Your branch is n commits behind master" - git fetch origin
3. git remote prune origin --dry-run