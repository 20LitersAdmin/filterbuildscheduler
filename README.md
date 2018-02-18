# README

## Things to do
5. Write tests until everyone is happy (*Ross*) because TDD is real.
6. JQuery registration form validations (use global .has-errors css, see user#edit for good example)
7. Available functions div as partial on more screens (e.g. event/closed, users/communication, events/lead, events/cancelled )

## System tests:
Reference: https://gist.github.com/them0nk/2166525
1. DONE: Visit the homepage
2. DONE: Visit the info page
3. DONE: Visit my account page
9. DONE: Edit my profile / set a password
9. DONE: Sign in / Sign out / Sign up
9. DONE: Reset my password
4. DONE: View an event (private vs. public, past vs. present, registered vs. not, admin, leader, builder, anon)
5. DONE: Register for an event
6. Cancel an event registration && Cancel someone else's registration
9. See a list of registrations for an event
9. Edit a registration && Edit someone else's registration
9. Send a message to all registered users
9. Share the event (fb, twitter, poster)
9. Print an attendance list
9. Restore a deleted event && associated registration
9. See a list of events that need leaders
9. Manage communication preferences
9. Manage closed events
9. See inventories index
9. View an existing inventory
9. Edit an existing inventory (test filtering with js: true)
9. Finalize an existing inventory
9. Make a new inventory (manual, shipping, receiving, event)
9. See orders needed
9. Edit a count (blanks are ignored)
9. Submit a partial count (box / loose)
9. See the count#edit calculator

## BUGS!! AH BUGS!!!
12. Inventories created from events aren't subtracting parts from components (parts used to build the technologies_built or boxes_packed)

## Remind myself:
1. production backup / development restore-from production
2. "Your branch is n commits behind master" - git fetch origin