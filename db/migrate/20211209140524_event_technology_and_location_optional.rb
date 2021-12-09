# frozen_string_literal: true

class EventTechnologyAndLocationOptional < ActiveRecord::Migration[6.1]
  def change
    change_column_null :events, :location_id, true
    change_column_null :events, :technology_id, true
  end
end
