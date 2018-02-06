# README

## Things to do
4. Check models for new methods needing specs (count, part, material, inventory, supplier)
5. Write tests until everyone is happy (*Ross*) because TDD is real.
12. Monthly report: structure and auto-send on first of every month
  * # of Boxed technologies
  * # of parts to order
  * total $ of parts to order
  * link to inventories/order
  * link to latest inventory
  * Email addresses attached as csv (Users.where(email_opt_out: false) created in last month)
  * Send to send_inventory_emails


## BUGS!! AH BUGS!!!
1. RegistrationController::Update -- need error handling line #30 and #46
2. accepts_nested_attributes_for seems to break event#show, at least for anon view
3. Supplier.valid_url? is still not ignoring null
12. Inventories created from events aren't subtracting parts from components (parts used to build the technologies_built or boxes_packed)


## ROSS: These things aren't pretty:
1. Registration.rb validations not working ( eg. :under_max_registration)
  * Patched my own solution into RegistrationController
3. Registration#create (via Event#show): registration_anonymous partial: How to handle form errors with f.error_notifiction and o.error_notification?

## ROSS: What would this cost?
4. Add a Stripe Webhook / API for CauseVox to replace Zapier
  * Accepting & reading Stripe webhook is working
  * Sending to Kindful is not

## Remind myself:
1. production backup / development restore-from production
2. "Your branch is n commits behind master" - git fetch origin