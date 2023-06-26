# Inventory System Overview
[Database diagram](https://dbdiagram.io/d/6498e56302bd1c4a5e0b0572)

## Tables related to items:
1. Technologies
Each record represents a water filtration or collection technology
Technologies are composed of components and parts in several steps.
The ones we care about:
* SAM3 - "Sand And Membrane" Household filter (id: 3, uid: "T003")
* SAM2 - "Sand And Membrane" Community filter (id: 7, uid: "T007")
* RWHS - "Rainwater Harvesting System" (id: 9, uid: "T009")
* MOF - "Membrane Only Filter" Household filter (id: 10, uid: "T010")
* Pump - "Backflush Pump" (id: 8, uid: "T008")

2. Components
A combination of two or more items (components or parts) that represent a completed step in the assembly process.

3. Parts
A basic "item" that can be used in an assembly. Parts are either purchased or made from materials.
Parts that are made from materials are indicated by the `made_from_materials` flag. Their cost is calculated from the cost of the materials used to make them.
Has a foreign key `material_id` to associate it with a material.

4. Materials
An "item" used to make parts. Never directly used in an assembly, must be made into parts first.

5. Assemblies
The polymorphic join table that connects technologies, components, and parts together in a tree structure.
"Combination" represents the parent, "item" represents the child.

Simple example:
1. Technology: Chair
2. Components: Frame, Back, Legs
3. Parts: Legs, Leg braces, Seat, Back arch, Back spindles, Screws
4. Materials: Dowels for spindles, Flat dimensional board for Seat

Assemblies:
1. Leg Parts and leg brace Parts are assembled into a Legs Component
2. Flat dimensional board Material is crafted into a Seat Part[^1]
3. Legs Component and Seat Part are assembled into a Frame Component
4. Spindle dowel materials are cut to length to form Back spindle Parts (1 dowel material produces 4 spindles)[^1]
5. Back spindle Parts are assembled with the Back arch Part into a Back Component
6. Frame Component and Back Component are assembled into a Chair Technology

[^1]: These relationships between `Parts` and `Materials` are not held by the `Assembly` model, but by the `"parts"."material_id"` foreign key and the `"parts"."quantity_from_material"` field. They are left in for clarity.

## Itemable concern
Items are: Technology, Component, Part, Material
Things Items have uniquely in common:
* `loose_count, box_count, available_count, quantity_per_box`
* `price`
* `history` - a record of historical inventory counts
* `quantities`
  - for `Technology`, this is a list of individual items and quantity of each that make up the technology. Helpful for calculating parts and materials quickly.
  - for all others, this is a list of the `Technologies` that use this item and at what quantity. Helpful for calculating orders quickly.

## Inventory tables
1. Inventory Table
A record of when and why an inventory was performed. Types of inventories include:
* Receiving - when a shipment of parts or materials is received
* Event - when an event is held and technologies or compoonents are produced
* Shipping - when a shipment of technologies (or maybe components) are shipped out
* Manual - when a full inventory is performed of one or more technologies

2. Counts Table
A transient record of the count of an item as `loose_count` and `box_count`.
It is polymorphically joined to one of the items (Technology, Component, Part or Material)
When the inventory is complete, the `CountTransferJob` is run to transfer the data to the specific item's record, including calculating `available_count` (based on `quantity_per_box * unopened_boxes_count`), and the count record is destroyed to save database space.
