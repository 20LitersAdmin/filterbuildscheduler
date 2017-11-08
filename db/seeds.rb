# # This file should contain all the record creation needed to seed the database with its default values.
# # The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

# Location.create!([
#   { name: 'Center of the Universe',
#     address1: "3501 Fairlanes Ave SW",
#     address2: "West side of the building",
#     city: "Grandville",
#     state: "MI",
#     zip: "49507",
#     map_url: "https://goo.gl/maps/ZgfJaae3ReJ2",
#     photo_url: "photo_url-filler-data",
#     instructions: "Park on West side of building, watch out for the alligator"
#   },
#   { name: 'Middle of Nowhere',
#     address1: "220 Alderman St",
#     address2: "West side of the building",
#     city: "Belding",
#     state: "MI",
#     zip: "48809",
#     map_url: "https://goo.gl/maps/ncrKcdMGsyK2",
#     photo_url: "photo_url-filler-data",
#     instructions: "Drive until civilization ends, then park and wait for nightfall."
#   }
# ])

# Technology.create!([
#   { name: "Bucket Filter",
#     description: "Designed by Village Water Filters and assembled by 20 Liters volunteers, this family-friendly build is open to people aged 4-104.",
#     ideal_build_length: 3,
#     ideal_group_size: 12,
#     ideal_leaders: 2,
#     family_friendly: true,
#     unit_rate: 2.13
#   },
#   { name: "Facility Filter",
#     description: "Got the engineering bug? Like to cut and glue PVC in complicated ways? Then this is the event for you.",
#     ideal_build_length: 4,
#     ideal_group_size: 4,
#     ideal_leaders: 1,
#     family_friendly: false,
#     unit_rate: 0.125
#   },
# ])

# Event.create!([
#   { start_time: 2.days.from_now,
#     end_time: 2.days.from_now,
#     title: "2 days from now",
#     description: "Open, public build. Anyone can come",
#     min_registrations: 1,
#     max_registrations: 10,
#     min_leaders: 1,
#     max_leaders: 3,
#     location: Location.first,
#     item_goal: 20,
#     technology_id: Technology.first.id
#   },
#   { start_time: 6.days.from_now,
#     end_time: 6.days.from_now,
#     title: "6 days from now",
#     description: "This one should be private, but the model is missing some fields.",
#     min_registrations: 1,
#     max_registrations: 10,
#     min_leaders: 1,
#     max_leaders: 3,
#     location: Location.second,
#     item_goal: 20,
#     technology_id: Technology.first.id
#   },
#   { start_time: 10.days.ago,
#     end_time: 9.days.ago,
#     title: "10 days ago",
#     description: "I'm an event in the past.",
#     min_registrations: 1,
#     max_registrations: 10,
#     min_leaders: 1,
#     max_leaders: 3,
#     location: Location.first,
#     item_goal: 20,
#     technology_id: Technology.second.id
#   }
# ])

# User.create!([
#   { email: "admin@email.com",
#     password: "password", password_confirmation: "password",
#     fname: "Admin",
#     lname: "Boss",
#     is_leader: true,
#     is_admin: true
#   },
#   { email: "leader1@email.com",
#     password: "password", password_confirmation: "password",
#     fname: "Leader",
#     lname: "One",
#     is_leader: true
#   },
#   { email: "leader2@email.com",
#     password: "password", password_confirmation: "password",
#     fname: "Leader",
#     lname: "Two",
#     is_leader: true
#   },
#   { email: "builder1@email.com",
#     password: "password", password_confirmation: "password",
#     fname: "Builder",
#     lname: "One"
#   },
#   { email: "builder2@email.com",
#     password: "password", password_confirmation: "password",
#     fname: "Builder",
#     lname: "Two"
#   },
#   { email: "builderMissing@email.com",
#     password: "password", password_confirmation: "password",
#     fname: "Builder",
#     lname: "Archived",
#     deleted_at: '2017-11-03 00:00:00'
#   },
#   { email: "builderNoPW@email.com",
#     fname: "Builder",
#     lname: "No Password"
#   },
# ])

Registration.create!([
  {
    user_id: 1,
    guests_registered: 2,
    event_id: 1,
    leader: true
  },
  {
    user_id: 2,
    guests_registered: 4,
    event_id: 1
  },
  {
    user_id: 3,
    guests_registered: 0,
    event_id: 1
  },
  {
    user_id: 4,
    guests_registered: 6,
    event_id: 1
  },
  {
    user_id: 5,
    guests_registered: 3,
    event_id: 1
  },
  {
    user_id: 7,
    guests_registered: 5,
    event_id: 1
  },
])
