# README

## Things to do
1. Send Gcal link and ics attachment on event registration email
1. Don't show leaders on attendance list
1. Show "You're leading" on Event#show events
1. Always email-remind Admins of upcoming builds (for prep and printing)
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

## BUGS! AHH! BUGS!
1. Cancelling a registration from an email:
  * 2017-11-17T06:43:38.884139+00:00 app[web.1]: [641df5f6-28a1-4649-bede-5c3d3f5deb0c] AbstractController::ActionNotFound (The action 'show' could not be found for RegistrationsController)
2. Users reported issues registering on mobile (iPhones?), probably anonymous?
3. /events/1/edit not submitting, but no errors (nested attributes?) -- only affects past events


