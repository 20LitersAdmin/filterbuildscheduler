# README

## Things to do
3. Technology Reorder report to match spreadsheet cols (calculate weeks until out, cost w/ wire transfer and shipping fees, total price [adjustable with checkboxes])
4. Technologies views:
  - list components and parts with quantities
  - Add pricing / ordering views
5. Write tests until everyone is happy (*Ross*) because TDD is real.
12. Monthly report: structure and auto-send

## BUGS!! AH BUGS!!!
11. Event changed email doesn't list technology changed as option
1. RegistrationController::Update -- need error handling line #30 and #46
2. accepts_nested_attributes_for seems to break event#show, at least for anon view
4. Registration#Edit always goes back to Event#Show
12. Inventories created from events aren't subtracting parts from components (parts used to build the technologies_built or boxes_packed)

## The Future
3. Track item inventory/count over time with a cool graph

## ROSS: These things aren't pretty:
1. Registration.rb validations not working ( eg. :under_max_registration)
  * Patched my own solution into RegistrationController
3. Registration#create (via Event#show): registration_anonymous partial: How to handle form errors with f.error_notifiction and o.error_notification?

## ROSS: What would this cost?
4. Add a Stripe Webhook / API for CauseVox to replace Zapier
  * Accepting & reading Stripe webhook is working
  * Sending to Kindful is not
