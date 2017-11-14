# README

## Things to do
1. Add inventory system functionality
  * Needs views / printable
  * Needs variance check
2. Created event pushes to Google Calendar
  * https://readysteadycode.com/howto-integrate-google-calendar-with-rails
  * https://github.com/northworld/google_calendar
2. Figure out Kindful API (Rails: RestClient gem)
  * https://github.com/delongtj/kindful_constant_contact
  * Decide on events -- have to have $$ amount [name, id, [contact],[transaction]]
  * Need to build confirm attendance (to trigger 'user attended event [instead of registering]')
  * KINDFUL_API/imports
  * Contact importing (w/ matching & group assignment)
  * Event importing (w/ matching [use "name", let Kindful create the ID])
  * Create POROs (update_contact, update_event)
  * Trigger POROs from controllers (user#create, user#update, event#create, event#update, registration#report)
2. Add a Stripe Webhook / API for CauseVox to replace Zapier
  * Accepting & reading Stripe webhook is working
  * Sending to Kindful is not
3. Roll in monthly reporting?

### Learning about Kindful's API
1. Seems to be focused around this model:
  * Import contact (assign external ID) with "update", while matching on [FName, LName, Email], assigning them to the groups ["15780" - builders, "22893" - leaders ]
  * Import event with "update", while matching on "name", let Kindful assign the event ID, must be done with contacts_with_transactions?
2. How to submit app key? In header?

## The Future
1. Use Paperclip to add part and component images


