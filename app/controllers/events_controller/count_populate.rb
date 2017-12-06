class EventsController
  class CountPopulate
    def initialize(event, inventory, user_id)
      @event = event
      @inventory = inventory
      @technology = @event.technology
      @user_id = user_id

      # Find the component that represents the completed technology
      @tech_component = @technology.primary_component

      # Find that component among the newly created counts
      @count_component = @inventory.counts.where(component_id: @tech_component.id).first_or_initialize
      if @event.technologies_built != nil
        @count_component.loose_count += @event.technologies_built
      end

      if @event.boxes_packed != nil
        @count_component.unopened_boxes_count += @event.boxes_packed
      end

      @count_component.user_id = @user_id
      @count_component.save
    end
  end
end
