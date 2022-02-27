# frozen_string_literal: true

class Label
  include ActiveModel::Model

  attr_accessor :name, :description, :uid, :technologies, :quantity_per_box, :picture, :only_loose, :box_type, :box_notes

  def only_loose?
    only_loose
  end
end
