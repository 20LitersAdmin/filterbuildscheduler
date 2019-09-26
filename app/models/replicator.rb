# frozen_string_literal: true

class Replicator
  include ActiveModel::Model

  attr_accessor :event_id
  attr_accessor :start_time
  attr_accessor :end_time
  attr_accessor :frequency
  attr_accessor :occurrences
end
