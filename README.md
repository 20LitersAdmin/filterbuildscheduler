# README

## Things to do
3. Updated event sends email when datetime/location changes
4. Cancelled event sends email to all registrants && users.where(send_notification_emails: true)
5. Allow leadership to email all registrants from registration#index

1. Need paper event evaluation forms
1. Add inventory system functionality
  * Needs views / printable
  * Needs variance check

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
1. Wait for live testing:
  * Do builders and admins get reminder emails?
  * Do people get emails if the event is in the past?

## BUGS! AHH! BUGS!
1. Registration.rb validations not working  ( eg. :under_max_registration)
  * Patched my own solution into RegistrationController


