# README

## Things to do
1. Destroy phone #.
4. Technologies views:
  - list components and parts with quantities
5. Do more testing on kindful push
6. Mess with reminder emails more...

## BUGS!! AH BUGS!!!
1. RegistrationController::Update -- need error handling line #30 and #46
2. accepts_nested_attributes_for seems to break event#show, at least for anon view
3. Reminder emails not sending: cron not firing? Postico

## The Future
1. Scenario: During a build event, we box technologies that we didn't build at that event. This will skew the inventory. (would need extra fields: boxes_packed_from_tech_we_made && boxes_packed_from_preexisting_tech )
3. Track item inventory/count over time with a cool graph
4. Roll in monthly reporting?


## ROSS: These things aren't pretty:
1. Registration.rb validations not working ( eg. :under_max_registration)
  * Patched my own solution into RegistrationController
2. Inventory stuff has a few join tables (e.g. extrapolate_technology_parts) which pose some challenges in RailsAdmin:
  * Creating a new record and trying to create the join record at the same time fails validation.
3. Registration#create (via Event#show): registration_anonymous partial: How to handle form errors with f.error_notifiction and o.error_notification?

## ROSS: What would this cost?
4. Add a Stripe Webhook / API for CauseVox to replace Zapier
  * Accepting & reading Stripe webhook is working
  * Sending to Kindful is not
5. Figure out Kindful API (Rails: RestClient gem)
  * make it a background job?
  * Get rid of phone #s (user model, forms, API call)
