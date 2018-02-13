# README

## Things to do
5. Write tests until everyone is happy (*Ross*) because TDD is real.
  * Learn to write system tests
  - https://chriskottom.com/blog/2017/04/full-stack-testing-with-rails-system-tests/
  - https://medium.com/table-xi/a-quick-guide-to-rails-system-tests-in-rspec-b6e9e8a8b5f6

## BUGS!! AH BUGS!!!
1. RegistrationController::Update -- need error handling line #30 and #46
2. accepts_nested_attributes_for seems to break event#show, at least for anon view
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