# README

## Things to do
1. Add inventory system functionality
  * Use DataTables for searching and sorting? (desktop views)
  * Throw variance check ( against Inventory.latest )
  * Extrapolate items from components
  * Event#report creates inventory and extrapolates items
  * Mark inventory complete && send emails
  * Add a reorder_level field to parts && materials instead of predicting?

3. Allow leadership to CRUD registrants for events.in_the_past
2. Allow leadership to email all registrants from registration#index

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
6. Roll in monthly reporting?

## The Future
1. Use Paperclip to add part and component images
1. Send email with weekly product availability (by user.primary_location == Business Connect?)
1. Track item inventory/count over time
1. Wait for live testing:
  * Do builders and admins get reminder emails?
  * Do registrants not get registration#created emails if the event is in the past?

## BUGS! AHH! BUGS!
1. Extrap tables in RailsAdmin -- "desc" does not exist
1. Registration.rb validations not working  ( eg. :under_max_registration)
  * Patched my own solution into RegistrationController

## Things that will annoy only me (and maybe Ross)
1. Links have "btn #color# devise" to stretch across screen. Should rename to "fullwidth"


