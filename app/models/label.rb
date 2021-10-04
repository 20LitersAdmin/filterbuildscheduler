# frozen_string_literal: true

class Label
  include ActiveModel::Model

  attr_accessor :name, :description, :uid, :technologies, :quantity_per_box, :image, :only_loose

  def only_loose?
    only_loose
  end

  def picture
    image.attached? ? image : 'http://placekitten.com/140/140'
  end
end
