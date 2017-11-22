# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

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
#   }
# ])

# Event.create!([
#   { start_time: 2.days.from_now,
#     end_time: 2.days.from_now,
#     title: "2 days from now",
#     description: "Open, public build. Anyone can come",
#     min_registrations: 1,
#     max_registrations: 30,
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
# Registration.create!([
#   {
#     user_id: 1,
#     guests_registered: 2,
#     event_id: 1,
#     leader: true
#   },
#   {
#     user_id: 2,
#     guests_registered: 4,
#     event_id: 1
#   },
#   {
#     user_id: 3,
#     guests_registered: 0,
#     event_id: 1
#   },
#   {
#     user_id: 4,
#     guests_registered: 6,
#     event_id: 1
#   },
#   {
#     user_id: 5,
#     guests_registered: 3,
#     event_id: 1
#   },
#   {
#     user_id: 7,
#     guests_registered: 5,
#     event_id: 1
#   },
# ])
# Material.create!([
#   {
#     name: 'PVC 2-inch schd 40',
#     supplier: 'Lowes',
#     price_cents: 499,
#     min_order: 1,
#     order_id: "PLB213-45",
#     weeks_to_deliver: 1.5
#   },
#   {
#     name: 'PVC 1/2-inch schd 40',
#     supplier: 'Lowes',
#     price_cents: 299,
#     min_order: 1,
#     order_id: "PLB213-40",
#     weeks_to_deliver: 1.2
#   },
#   {
#     name: 'Hose 1/2-inch-ID clear flexible',
#     supplier: 'Hoses Online',
#     price_cents: 1600,
#     min_order: 1,
#     order_id: "HO-2345",
#     weeks_to_deliver: 3
#   },
#   {
#     name: 'Lumber 2x4x8 pine',
#     supplier: 'Lowes',
#     price_cents: 505,
#     min_order: 1,
#     order_id: "LMB456-01",
#     weeks_to_deliver: 1.5
#   }
# ])

# Part.create!([
#   {
#     name: "PVC Endcaps 1/2-inch",
#     supplier: 'SupplyHouse.com',
#     order_url: 'https://www.supplyhouse.com',
#     price_cents: 925,
#     min_order: 50,
#     order_id: "615-27",
#     common_id: "half inch endcaps undrilled",
#     weeks_to_deliver: 2,
#     sample_size: 10,
#     sample_weight: 1.125
#   },
#   {
#     name: "PVC Endcaps 1/2-inch drilled",
#     common_id: "half inch endcaps drilled",
#     price_cents: 15,
#     weeks_to_deliver: 2,
#     sample_size: 10,
#     sample_weight: 1.025
#   },
#   {
#     name: "Backwash hose",
#     common_id: "backwash hose cut",
#     price_cents: 0,
#     sample_size: 10,
#     sample_weight: 3,
#     made_from_materials: true,
#   },
#   {
#     name: "Filter Cartridge 3-inch",
#     supplier: 'NOK',
#     price_cents: 704,
#     min_order: 500,
#     order_id: "HFMC360211572",
#     weeks_to_deliver: 16,
#     sample_size: 50,
#     sample_weight: 5.25
#   },
#   {
#     name: "35-mm O-ring",
#     supplier: 'NOK',
#     price_cents: 12,
#     min_order: 1200,
#     order_id: "HFMC360211572-01",
#     common_id: "Filter o-ring thick",
#     weeks_to_deliver: 16,
#     sample_size: 100,
#     sample_weight: 0.125
#   },
#   {
#     name: "32-mm O-ring",
#     supplier: 'NOK',
#     price_cents: 8,
#     min_order: 1200,
#     order_id: "HFMC360211572-02",
#     common_id: "Filter o-ring thin",
#     weeks_to_deliver: 16,
#     sample_size: 100,
#     sample_weight: 0.125
#   },
#   {
#     name: "Molded long filter housing component blue",
#     supplier: 'WeMakeYourPlastics',
#     price_cents: 200,
#     min_order: 100,
#     order_id: "050WMYP-01",
#     common_id: "Blue long component",
#     weeks_to_deliver: 10,
#     sample_size: 5,
#     sample_weight: 1.6
#   },
#   {
#     name: "Molded short filter housing component blue",
#     supplier: 'WeMakeYourPlastics',
#     price_cents: 200,
#     min_order: 100,
#     order_id: "050WMYP-02",
#     common_id: "Blue short component",
#     weeks_to_deliver: 10,
#     sample_size: 8,
#     sample_weight: 1.2
#   }
# ])
#
#  # Totally real data
# User.create!([
#   { email: 'andrew@20liters.org', fname: 'Andrew', lname: 'Vantimmeren', phone: '616.710.6392'},
#   { email: 'lizzylouwho@gmail.com', fname: 'Liz', lname: 'Sitte', phone: '6164027949', is_leader: true},
#   { email: 'bjlong5@hotmail.com', fname: 'Bob', lname: 'Long', phone: '6169016615', is_leader: true},
#   { email: 'cmjohnson177@gmail.com', fname: 'Chris', lname: 'Johnson', phone: '616-490-0356'},
#   { email: 'codye@foreway.com', fname: 'Cody', lname: 'Ensing', phone: '616-401-9862', does_inventory: true},
#   { email: 'dlathrop@steelcase.com', fname: 'Dave', lname: 'Lathrop', phone: '616-901-2912', is_leader: true, does_inventory: true},
#   { email: 'dougv@cqlcorp.com', fname: 'Doug', lname: 'VandenHoek', phone: '616.307.0018', is_leader: true},
#   { email: 'jrcardinal@highpointelectric.us', fname: 'Jon', lname: 'Cardinal', phone: '231.638.6089', is_leader: true},
#   { email: 'lmont71@comcast.net', fname: 'Linda', lname: 'Montgomery', phone: '6164194256', is_leader: true, does_inventory: true},
#   { email: 'liz.jasperse@gmail.com', fname: 'Liz', lname: 'Jaspers', phone: '616-990-4402', does_inventory: true},
#   { email: 'peter.vandentoorn@gmail.com', fname: 'Peter', lname: 'VandenToorn', phone: '616.822.7498', is_admin:  true},
#   { email: 'snauta74@hotmail.com', fname: 'Steve', lname: 'Nauta', phone: '6164467674', is_leader: true, does_inventory: true},
#   { email: 'thadcummings@gmail.com', fname: 'Thad', lname: 'Cummings', phone: '248-982-7024', is_leader: true},
#   { email: 'ta3jwiersma@gmail.com', fname: 'Tim', lname: 'Wiersma', phone: '616-914-7971', does_inventory: true},
#   { email: 'thamel53@gmail.com', fname: 'Tom', lname: 'Hamel', phone: '231.301.2957', is_leader: true},
#   { email: 'tommaas@hotmail.com', fname: 'Tom', lname: 'Maas', phone: '616.901.6113', is_leader: true},
#   { email: 'tonytheclimber@gmail.com', fname: 'Tony', lname: 'Kelly', phone: '6163899936', is_leader: true, does_inventory: true},
#   { email: 'bullers_us@yahoo.com', fname: 'Vern', lname: 'Bullers', phone: '541-221-8579', is_leader: true }
# ])
Part.create!([
  { name: '1/2-inch Floor Flange', supplier: 'SupplyHouse.com', price_cents: 177, min_order: 100, weeks_to_deliver: 4, quantity_per_box: 25},
  { name: '10-inch Core', supplier: 'NOK Corporation', price_cents: 5572, min_order: 64, weeks_to_deliver: 19, quantity_per_box: 16},
  { name: '12-inch Housing', supplier: 'Reserve Filter International', price_cents: 2791, min_order: 64, weeks_to_deliver: 8},
  { name: '2 Hole Strap', supplier: 'Lowes', price_cents: 29, min_order: 300, weeks_to_deliver: 1},
  { name: '3-inch core', supplier: 'NOK Corp', price_cents: 608, min_order: 10800, additional_cost_cents: 149015, weeks_to_deliver: 19, quantity_per_box: 240},
  { name: 'Black O-ring', supplier: 'The O-Ring Store', price_cents: 3, min_order: 30000, additional_cost_cents: 499, weeks_to_deliver: 3},
  { name: 'Filter Housing Long (blue)', supplier: 'Crosspoint International', price_cents: 42, min_order: 20000, weeks_to_deliver: 22, quantity_per_box: 484},
  { name: 'Filter Housing Short (blue)', supplier: 'Crosspoint International', price_cents: 35, min_order: 20000, weeks_to_deliver: 22, quantity_per_box: 1000},
  { name: 'Foam Inserts', supplier: 'Foamulations', price_cents: 103, min_order: 3000, additional_cost_cents: 28691, weeks_to_deliver: 9},
  { name: 'Hook - plastic (blue)', supplier: 'Crosspoint International', price_cents: 16, min_order: 20000, weeks_to_deliver: 22, quantity_per_box: 2800},
  { name: 'Instructions - VF100', supplier: 'Bob Ashley', price_cents: 10, min_order: 1, weeks_to_deliver: 1},
  { name: 'Instructions - VF500', supplier: 'Bob Ashley', price_cents: 10, min_order: 1, weeks_to_deliver: 1},
  { name: 'Filter Housing Long (clear)', supplier: 'Crosspoint International', price_cents: 42, min_order: 10000, weeks_to_deliver: 22, quantity_per_box: 484},
  { name: 'Metal mounting bracket', supplier: 'Reserve Filter International', price_cents: 170, min_order: 64, weeks_to_deliver: 8, quantity_per_box: 1000},
  { name: 'Nut - plastic (blue)', supplier: 'Crosspoint International', price_cents: 13, min_order: 20000, weeks_to_deliver: 22},
  { name: 'PCV Tee', supplier: 'PPS', price_cents: 24, min_order: 600, weeks_to_deliver: 4},
  { name: 'Plastic Bags', supplier: 'Uline', price_cents: 11, min_order: 5000, additional_cost_cents: 11202, weeks_to_deliver: 1},
  { name: 'Prefilter', supplier: 'QC Supply', price_cents: 5500, min_order: 12, additional_cost_cents: 2720, weeks_to_deliver: 8},
  { name: 'Pressure Valve', supplier: 'Zoro', price_cents: 4057, min_order: 32, weeks_to_deliver: 8},
  { name: 'PVC 3/4-inch Adapter Female', supplier: 'PPS', price_cents: 24, min_order: 200, weeks_to_deliver: 4, quantity_per_box: 50},
  { name: 'PVC 3/4-inch X 1/2-inch Slip Tee', supplier: 'PPS', price_cents: 74, min_order: 100, weeks_to_deliver: 4},
  { name: 'PVC 90-degree 406', supplier: 'PPS', price_cents: 19, min_order: 900, weeks_to_deliver: 4, quantity_per_box: 50},
  { name: 'PVC 90-degree Street 409', supplier: 'PPS', price_cents: 59, min_order: 100, weeks_to_deliver: 4},
  { name: 'PVC 90-degree Threaded 407', supplier: 'PPS', price_cents: 24, min_order: 200, weeks_to_deliver: 4, quantity_per_box: 50},
  { name: 'PVC 3/4-inch Cap', supplier: 'PPS', price_cents: 18, min_order: 100, weeks_to_deliver: 4},
  { name: 'PVC 3/4-inch Cross', supplier: 'PPS', price_cents: 106, min_order: 100, weeks_to_deliver: 4, quantity_per_box: 50},
  { name: 'Saddle - plastic (blue)', supplier: 'Crosspoint International', price_cents: 27, min_order: 20000, weeks_to_deliver: 22, quantity_per_box: 1300},
  { name: 'Hex Screw for 12-inch Plastic Housing', supplier: 'Zoro', price_cents: 5, min_order: 256, weeks_to_deliver: 4, quantity_per_box: 100},
  { name: 'Finish Wood Screw', supplier: 'Zoro', price_cents: 3, min_order: 2000, weeks_to_deliver: 4, quantity_per_box: 100},
  { name: 'Shipping Box 20x20x20', supplier: 'Uline', price_cents: 206, min_order: 100, additional_cost_cents: 12181, weeks_to_deliver: 1},
  { name: 'Shipping Box 32x12x10', supplier: 'Uline', price_cents: 188, min_order: 100, additional_cost_cents: 12419, weeks_to_deliver: 1},
  { name: 'Shipping Box NOK (from 3-inch cartrige)', supplier: 'NOK', price_cents: 0, weeks_to_deliver: 0, quantity_per_box: 1},
  { name: 'Filter Housing Short (clear)', supplier: 'Crosspoint International', price_cents: 35, min_order: 10000, weeks_to_deliver: 22, quantity_per_box: 1000},
  { name: 'Syringes', supplier: 'LanYuan/Flora', price_cents: 16, min_order: 20000, additional_cost_cents: 163986, weeks_to_deliver: 10, quantity_per_box: 500},
  { name: 'Thick O-ring', supplier: 'NOK Corp', price_cents: 9, min_order: 10800, weeks_to_deliver: 19, quantity_per_box: 6000},
  { name: 'Thin O-ring', supplier: 'NOK Corp', price_cents: 8, min_order: 10800, weeks_to_deliver: 19, quantity_per_box: 4000},
  { name: 'Toggle Bolt', supplier: 'Zoro', price_cents: 27, min_order: 1000, weeks_to_deliver: 4, quantity_per_box: 50},
  { name: 'Tube Clamp', supplier: 'Ningbo Finer Medical', price_cents: 8, min_order: 20000, additional_cost_cents: 635, weeks_to_deliver: 6, quantity_per_box: 2500},
  { name: 'Tubing - 12-inch', supplier: 'Kent Systems', price_cents: 36, min_order: 10000, additional_cost_cents: 12366, weeks_to_deliver: 1},
  { name: 'Tubing - 2-inch', supplier: 'Kent Systems', additional_cost_cents: 1500, weeks_to_deliver: 1},
  { name: 'Valves', supplier: 'Sanking', price_cents: 304, min_order: 269, additional_cost_cents: 33534, weeks_to_deliver: 8, quantity_per_box: 60},
  { name: 'Rubber Washer beveled', supplier: 'Tomlinson Industries', price_cents: 7, min_order: 40000, additional_cost_cents: 83945, weeks_to_deliver: 6, order_id: 1903515},
  { name: 'Rubber Washer large hole', supplier: 'Tomlinson Industries', price_cents: 9, min_order: 20000, additional_cost_cents: 83945, weeks_to_deliver: 6, order_id: 1903271},
  { name: 'Rubber Washer small hole', supplier: 'Tomlinson Industries', price_cents: 8, min_order: 20000, additional_cost_cents: 101445, weeks_to_deliver: 6, order_id: 1925110},
  { name: '1/2-inch X 2-inch Galv Pipe', supplier: 'Zoro', price_cents: 56, min_order: 100, weeks_to_deliver: 4, quantity_per_box: 25},
  { name: '1/4-inch X 2-inch Galv Pipe', supplier: 'Zoro', price_cents: 67, min_order: 64, weeks_to_deliver: 4},
  { name: '3/4-inch X Short Galv Pipe', supplier: 'Zoro', price_cents: 53, min_order: 200, weeks_to_deliver: 4, quantity_per_box: 25},
  { name: '3/4-inch X 3-inch Galv Pipe', supplier: 'Zoro', price_cents: 94, min_order: 200, weeks_to_deliver: 4, quantity_per_box: 25},
  { name: '3/4-inch to 1/4-inch Galv Bushing', supplier: 'Zoro', price_cents: 102, min_order: 64, weeks_to_deliver: 4},
  { name: 'Adaptor FGHT to 1/4-inch barbed', supplier: 'Crosspoint International', price_cents: 18, min_order: 20000, additional_cost_cents: 7000, weeks_to_deliver: 22, quantity_per_box: 3000  }
])
Material.create!([
  { name: 'PVC 2-inch X 10-feet', supplier: 'Lowes', price_cents: 695, min_order: 1, weeks_to_deliver: 1, quantity_per_box: 1},
  { name: 'PVC 3/4-inch X 10-feet', supplier: 'Lowes', price_cents: 228, min_order: 1, weeks_to_deliver: 1, quantity_per_box: 1},
  { name: 'Treated 2/4 Wood 8-feet', supplier: 'Lowes', price_cents: 517, min_order: 1, weeks_to_deliver: 1, quantity_per_box: 1},
  { name: 'Packing Tape', supplier: 'Uline'   , weeks_to_deliver: 1, quantity_per_box: 36},
])
Component.create!([
  { name: '3-inch core w/ o-rings', quantity_per_box: 240},
  { name: '3-inch assembled cartridges unwelded'},
  { name: '3-inch assembled cartridges welded'},
  { name: 'Bucket Filter - VF100', completed_tech: true, quantity_per_box: 125, sample_size: 10},
  { name: 'Facility Filter - VFF500', completed_tech: true, quantity_per_box: 1, sample_size: 1},
  { name: 'Prefilter - VF200', completed_tech: true, quantity_per_box: 150, sample_size: 20},
  { name: 'VFF500 manifold section', quantity_per_box: 1, sample_size: 1},
  { name: 'VFF500 regulator section', quantity_per_box: 1, sample_size: 1},
  { name: 'VFF500 cartridge section', quantity_per_box: 1, sample_size: 1},
  { name: 'VFF500 drain pieces', quantity_per_box: 1, sample_size: 1},
  { name: 'VFF500 stem pipe - 405mm', quantity_per_box: 1, sample_size: 1 }
=======
# User.create!([
#   { email:  'andrew@20liters.org' , fname:  'Andrew'  , lname:  'Vantimmeren' , phone:  '616.710.6392' },
#   { email:  'lizzylouwho@gmail.com' , fname:  'Liz' , lname:  'Sitte' , phone:  '6164027949'  , is_leader: true },
#   { email:  'bjlong5@hotmail.com' , fname:  'Bob' , lname:  'Long'  , phone:  '6169016615'  , is_leader:  true },
#   { email:  'cmjohnson177@gmail.com'  , fname:  'Chris' , lname:  'Johnson' , phone:  '616-490-0356' },
#   { email:  'codye@foreway.com' , fname:  'Cody'  , lname:  'Ensing'  , phone:  '616-401-9862'      , does_inventory: true },
#   { email:  'dlathrop@steelcase.com'  , fname:  'Dave'  , lname:  'Lathrop' , phone:  '616-901-2912'  , is_leader:  true  , does_inventory: true },
#   { email:  'dougv@cqlcorp.com' , fname:  'Doug'  , lname:  'VandenHoek'  , phone:  '616.307.0018'  , is_leader:  true },
#   { email:  'jrcardinal@highpointelectric.us' , fname:  'Jon' , lname:  'Cardinal'  , phone:  '231.638.6089'  , is_leader:  true },
#   { email:  'lmont71@comcast.net' , fname:  'Linda' , lname:  'Montgomery'  , phone:  '6164194256'  , is_leader:  true  , does_inventory: true },
#   { email:  'liz.jasperse@gmail.com'  , fname:  'Liz' , lname:  'Jaspers' , phone:  '616-990-4402'      , does_inventory: true },
#   { email:  'peter.vandentoorn@gmail.com' , fname:  'Peter' , lname:  'VandenToorn' , phone:  '616.822.7498'      , is_admin:   true },
#   { email:  'snauta74@hotmail.com'  , fname:  'Steve' , lname:  'Nauta' , phone:  '6164467674'  , is_leader:  true  , does_inventory: true },
#   { email:  'thadcummings@gmail.com'  , fname:  'Thad'  , lname:  'Cummings'  , phone:  '248-982-7024'  , is_leader:  true },
#   { email:  'ta3jwiersma@gmail.com' , fname:  'Tim' , lname:  'Wiersma' , phone:  '616-914-7971'      , does_inventory: true },
#   { email:  'thamel53@gmail.com'  , fname:  'Tom' , lname:  'Hamel' , phone:  '231.301.2957'  , is_leader:  true },
#   { email:  'tommaas@hotmail.com' , fname:  'Tom' , lname:  'Maas'  , phone:  '616.901.6113'  , is_leader:  true },
#   { email:  'tonytheclimber@gmail.com'  , fname:  'Tony'  , lname:  'Kelly' , phone:  '6163899936'  , is_leader:  true  , does_inventory: true },
#   { email:  'bullers_us@yahoo.com'  , fname:  'Vern'  , lname:  'Bullers' , phone:  '541-221-8579'  , is_leader:  true }
# ])
Registration.create!([
  {
    user_id: 1,
    guests_registered: 2,
    event_id: 5,
    leader: true
  },
  {
    user_id: 2,
    guests_registered: 4,
    event_id: 5
  },
  {
    user_id: 3,
    guests_registered: 0,
    event_id: 5
  },
  {
    user_id: 4,
    guests_registered: 6,
    event_id: 5
  },
  {
    user_id: 5,
    guests_registered: 3,
    event_id: 5
  },
  {
    user_id: 7,
    guests_registered: 5,
    event_id: 5
  },
  {
    user_id: 1,
    guests_registered: 2,
    event_id: 6,
    leader: true
  },
  {
    user_id: 2,
    guests_registered: 4,
    event_id: 6,
    leader: true
  },
  {
    user_id: 3,
    guests_registered: 0,
    event_id: 6
  },
  {
    user_id: 4,
    guests_registered: 6,
    event_id: 6
  },
  {
    user_id: 5,
    guests_registered: 3,
    event_id: 6
  },
  {
    user_id: 7,
    guests_registered: 5,
    event_id: 6
  }
])
