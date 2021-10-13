# frozen_string_literal: true

class AssemblyService
  # given an item and a goal, "assemble" combinations to match the goal
  # using item and any children
  attr_accessor :map, :remainder, :assembly, :goal, :item, :combination

  def initialize(combination, goal)
    @combination = combination
    @assembled = 0
    @remainder = goal
    @log = []
  end
end
