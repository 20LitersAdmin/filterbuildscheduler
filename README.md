# README

## Things to do
4. Technologies views:
  - list components and parts with quantities
5. Write tests until everyone is happy (*Ross*) because TDD is real.

## BUGS!! AH BUGS!!!
1. RegistrationController::Update -- need error handling line #30 and #46
2. accepts_nested_attributes_for seems to break event#show, at least for anon view
4. Registration#Edit always goes back to Event#Show
5. Registration#Edit -- checking the as_leader? box leads to error. Eg: Event/3/Registration/26

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
5. Figure out Kindful API
  * make it a background job?