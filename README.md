# README
## Kindful Mail Client
1. Setup
  - 20Liters-owned application, restricted to internal users
  - Google OAuth integration with User
  - Google Mail API
  - Kindful Querying: https://developer.kindful.com/customer/querying-guide/contact-queries

2. Workflow:
  - On a Cron job, once a day
  - Check for new mail in user's inbox (how to tell what's new?)
  - Query Kindful for the sender/receiver's email address (email || alt_email)
  - create `contact_w_note` if match
  - somehow keep track of which emails have been checked?

3. Structures:
  - Keep using KindfulClient
    - querying
    - creating
      - note formatting
  - Create GmailClient
    - OAuth
    - email reading
    - return msg body for note formatting

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
