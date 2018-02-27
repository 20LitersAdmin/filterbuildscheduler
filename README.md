# README

## Things to do
5. Write tests until everyone is happy (*Ross*) because TDD is real.
6. JQuery registration form validations (use global .has-errors css, see user#edit for good example)
7. Available functions div as partial on more screens (e.g. event/closed, users/communication, events/lead, events/cancelled )
8. View for technology assembly (which items [comps and parts] and #s on hand) -- shows what is needed and how many tech can be built with what's on hand
9. Count.item.has_no_box? to hide box count field on Count#edit

## System tests:
Reference: https://gist.github.com/them0nk/2166525
I made a generator: rails g spec SpecName SpecType
1. DONE: Visit the homepage
2. DONE: Visit the info page
3. DONE: Visit my account page
9. DONE: Edit my profile / set a password
9. DONE: Sign in / Sign out / Sign up
9. DONE: Reset my password
4. DONE: View an event (private vs. public, past vs. present, registered vs. not, admin, leader, builder, anon)
5. DONE: Register for an event
6. DONE: Edit / Cancel an event registration && Edit / Cancel someone else's registration
9. DONE: Create an event (admin, leader, not builder, not admin)
9. DONE: Managage an event (admin, leader, not builder, not admin)
9. DONE: Send a message to all registered users
9. DONE: Share the event (fb, twitter, poster)
9. DONE: Print an attendance list
9. DONE: Create an event report (close the event, and create related inventory)
9. DONE: Restore a deleted event && || associated registration
9. DONE: See a list of events that need leaders
9. DONE: Manage closed events
9. DONE: See inventories index
9. DONE: Manage communication preferences
9. DONE: View an existing inventory
9. DONE: Edit an existing inventory (test filtering with js: true) && Finalize
9. DONE: Make a new inventory (manual, shipping, receiving, event)
9. DONE: See orders needed
9. DONE: Edit a count (blanks are ignored) && Submit a partial count (box / loose) && See/use the count#edit calculator

## HMMM
1. Inventories created from events aren't subtracting parts from components (parts used to build the technologies_built or boxes_packed)
2. `weeks_to_out` and `per_technology` rely on lots of `.first`s which is an issue for items that `have_many` technologies

## Remind myself:
1. production backup / development restore-from production
2. "Your branch is n commits behind master" - git fetch origin