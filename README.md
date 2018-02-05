# README

## THIS NEXT PUSH
1. Heroku db:rollback -- for dropping parts#supplier_name
2. Uncomment the remove_supplier_name... stuff
3. Push again
4. Heroku db:migrate -- catch fixed remove_supplier_name... stuff and prod_rate to technology
5. Technology.all.each do |t| set prod_rate to 1

## Things to do
3. Technology Reorder report to match spreadsheet cols (calculate weeks until out, cost w/ wire transfer and shipping fees, total price [adjustable with checkboxes])
 - Needs: Parts table partial in _order_suppliers
 - Needs: Two total fields, one for each div
 - Needs: JS to distinguish between checkboxes from each div
 - Needs: JS to toggle button, div and total field
 - Needs: Calculate weeks until out
 - Needs: Calculate unit cost (combo of price and other fields? Or show all fields with low priority)
 - Needs: Calculate total cost
 - Needs: Order quantity field, min: min_order, recalcs total cost && order total
 4. Inventory#show - Reorder items should have ^ these cols instead of current cols
5. Write tests until everyone is happy (*Ross*) because TDD is real.
12. Monthly report: structure and auto-send on first of every month

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