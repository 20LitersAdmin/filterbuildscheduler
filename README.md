# README

## Things to do
1. Reorder_level field on parts && materials
   * First calculate vals: 2 months == 6k bucket filters && 10 facility filters. && 3k prefilters
   * On Inventory#show at the top
   * In the Inventory notify email
2. Allow leadership to CRUD registrants for events.in_the_past
3. Allow leadership to email all registrants from registration#index

8. Technologies views:
  - list components and parts with quantities

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
  * https://github.com/delongtj/kindful_constant_contact
  * head: https://developer.kindful.com/docs/direct-access
  * Need to build confirm attendance (to trigger 'user attended event [instead of registering]')
  * KINDFUL_API/imports
  * Contact importing (w/ matching & group assignment)
  * Event importing (w/ matching [use "name", let Kindful create the ID])
  * Create POROs (update_contact, update_event)
  * Trigger POROs from controllers (user#create, user#update, event#create, event#update, registration#report)


