class EventsController
  class CountPopulate
    def initialize(event, inventory, user_id)
      @event = event
      @inventory = inventory
      @technology = @event.technology
      @user_id = user_id

      # Find the component that represents the completed technology
      @component_ids = @technology.extrapolate_technology_components.map { |c| c.component_id }
      @tech_component = Component.where(id: @component_ids).where(completed_tech: true).first

      # Find that component among the newly created counts
      @count_component = @inventory.counts.where(component_id: @tech_component.id).first
      @count_component.loose_count += @event.technologies_built
      @count_component.unopened_boxes_count += @event.boxes_packed
      @count_component.user_id = @user_id
      @count_component.save
    end
  end
end
