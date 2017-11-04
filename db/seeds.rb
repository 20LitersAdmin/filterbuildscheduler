# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

location = Location.create(
  name: 'Main Workshop',
  address1: "address1-filler-data",
  address2: "address2-filler-data",
  city: "city-filler-data",
  state: "state-filler-data",
  zip: "zip-filler-data",
  map_url: "map_url-filler-data",
  photo_url: "photo_url-filler-data",
  instructioons: "instructioons-filler-data",
)

event = Event.create(
  start_time: 2.days.from_now,
  end_time: 2.days.from_now,
  title: "title-filler-data",
  description: "description-filler-data",
  min_registrations: 1,
  max_registrations: 10,
  min_leaders: 1,
  max_leaders: 3,
  location: location
)
