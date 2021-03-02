# README
## Kindful Mail Client
2. Check if email is from Org
3. Email#organization? on before_create
4. Need a cron job for checking Organizations 1x week

## HMMM
1. `weeks_to_out` and `per_technology` rely on lots of `.first`s which is an issue for items that `have_many` technologies
- Part#technology
- Material#technologydev
- Component#technologies
2. Tech Status sux big ones and needs some work (the 4-level deep problem)
3. EventsController::SubtractSubsets.subtract! only goes 1 level deep.

## Remind myself:
1. production backup / development restore-from production
  - `User.first.reset_password("password", "password")`
2. `Record.only_deleted.each do |record| record.really_destroy! end`
3. `orphans = User.builders.left_outer_joins(:registrations).where(registrations: { id: nil })`
