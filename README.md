# README

## Things to do
3. Technology Reorder report to match spreadsheet cols (calculate weeks until out, cost w/ wire transfer and shipping fees, total price [adjustable with checkboxes])
4. Technologies views:
  - list components and parts with quantities
  - Add pricing / ordering views
  - if made_from_materials, don't include on list.
5. Write tests until everyone is happy (*Ross*) because TDD is real.
12. Monthly report: structure and auto-send on first of every month
13. Tests for new comments fields: parts, materials, components, technologies
14. Remove the redundent fields from Part and Material (after copying stuff over)
15. All the monetize calls on models are redundent. See supplier_part for a good example
16. Test for new models: supplier, supplier_part, supplier_material

66. SUPPLIERS model with:
  - Name
  - URL
  - POC (name, email, phone, address)
  - Comments
  - Joins: Parts (many parts, many suppliers), Materials (many materials, many suppliers)

67. List of builds that still need leaders
  - ROOT/events/lead
  - Click link to go to event#show

## BUGS!! AH BUGS!!!
1. RegistrationController::Update -- need error handling line #30 and #46
2. accepts_nested_attributes_for seems to break event#show, at least for anon view
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

## Remind myself:
1. development restore-from production
2. "Your branch is n commits behind master" - git fetch origin