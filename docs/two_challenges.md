# Two inventory challenges

## Extrapolate changes down the tree.
If I indicate that I have built a certain number of Technologies or Components, then the system should:
* be able to extrapolate that change down the tree to all the Components, Parts, and Materials that make up those items.
* gracefully handle "opening" boxes when the `loose_count` is insufficient
* set counts to zero if there are insufficient items available
* turn materials into parts as needed to satisfy the counts

My current attempt is the `extrapolate_inventory_job` and `event_inventory_job`

## Determine "Produceable" items
Given my current inventory, the system should:
* be able to indicate how many components and technologies can be produced
* recognize that parts and components can be shared across technologies and components and "portion" them out based upon two factors: the number needed to reach the goal for each item, and the number of items that can be made from the available parts and components.
* recognize that materials can be shared across parts and "portion" them out based upon two factors: the number needed to reach the goal for each part, and the number of parts that can be made from the available materials.

My current attempt is the `produceable_job`
