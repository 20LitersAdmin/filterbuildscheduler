# README

## Things to do
1. Registration capping is not working... registration.rb validate :under_max_registration
  * Patched my own solution into RegistrationController
  * Maybe display "Room for ## more" instead of total registered?
1. Need paper event evaluation forms
1. Add inventory system functionality
  * Needs views / printable
  * Needs variance check
3. Updated event sends email when datetime/location changes
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
1. Wait for live testing - do builders and admins get reminder emails?

## BUGS! AHH! BUGS!
1. Cancelling a registration from an email:
  * AbstractController::ActionNotFound (The action 'show' could not be found for RegistrationsController)
3. /events/1/edit not submitting, but no errors (nested attributes?) -- only affects past events
4. bad route: https://make.20liters.org/admin/event/1/edit


