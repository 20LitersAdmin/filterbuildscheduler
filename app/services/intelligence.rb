class Intellegence

  def extrapolate(component)
    # calculate the number of parts in a component
    # adjust the count accordingly
  end

  def inventory_on_hand(part)
    # don't count component::parts marked as completed_tech || completed_tech_boxes
  end

  def inventory_not_shipped(model)
    # count component::parts marked as completed_tech, but not completed_tech_boxes
  end

  def predicition(model)
    # how many do we have on hand?
    # Look at last inventory.latest.date and subtract the blow-out of events.item_results
  end

  def forecast(model)
    # when will this item need to be ordered? Based on inventory_on_hand
    # look at upcoming builds::registrations && builds.length && builds.goal for associated technology#unit_rate vs predicted quantity
  end

  def suggest_goal(event)
    # What should the event's goal be?
    # look at past Event.where(technology_id: event.technology_id) and average item_results
  end

end
