# README

## Things to do
1. Add inventory system functionality
  * Needs views / printable
  * Needs variance check
2. Cancelled event sends email
3. Updated event sends email when datetime/location changes
4. Add a Stripe Webhook / API for CauseVox to replace Zapier
  * Accepting & reading Stripe webhook is working
  * Sending to Kindful is not
5. Figure out Kindful API (Rails: RestClient gem)
  * https://github.com/delongtj/kindful_constant_contact
  * Decide on events -- have to have $$ amount [name, id, [contact],[transaction]]
  * Need to build confirm attendance (to trigger 'user attended event [instead of registering]')
  * KINDFUL_API/imports
  * Contact importing (w/ matching & group assignment)
  * Event importing (w/ matching [use "name", let Kindful create the ID])
  * Create POROs (update_contact, update_event)
  * Trigger POROs from controllers (user#create, user#update, event#create, event#update, registration#report)
6. Roll in monthly reporting?

## The Future
1. Use Paperclip to add part and component images


