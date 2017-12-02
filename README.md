# README

## Things to do
1. Add inventory system functionality
  * Start with zeros. BUT AFTER FIRST SUBMIT: Show val (need solution for shipping && receiving)
  * Extrapolate items from components eg "count.part.extrapolate_component_parts.first.parts_per_component" -- but how to adjust for 2nd round edits?
  * Handle count form has null value. Set to 0
  * Counts: add button for partial count ( don't set user_id )
  * Event#report creates inventory and extrapolates items
  * Mark inventory complete && send emails
    - Link to current inventory#show
    - List of supplies needing re-order
  * Add a reorder_level field to parts && materials instead of predicting?

2. Allow leadership to CRUD registrants for events.in_the_past
3. Allow leadership to email all registrants from registration#index

8. Technologies views:
  - list components and parts with quantities


## The Future
1. Use Paperclip to add part and component images
2. Send email with weekly product availability (by user.primary_location == Business Connect?)
3. Track item inventory/count over time
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


