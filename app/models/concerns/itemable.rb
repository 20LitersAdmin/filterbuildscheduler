# frozen_string_literal: true

module Itemable
  extend ActiveSupport::Concern

  # Things Items have uniquely in common:
  # UIDs
  # Assemblies (except Technology can only be combination; Part can only be item)
  # loose_count, box_count, available_count, quantity_per_box
  # history
  # quantities (except Technology#quantities includes C, P, M, the others just include Tech)
  # price
  # label

  included do
    monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

    after_save :check_uid
  end

  def history_only(key)
    history.map { |h| { h[0] => h[1][key] } }
  end

  def history_series
    [
      { name: 'Available', data: history_only('available') },
      { name: 'Loose Count', data: history_only('loose') },
      { name: 'Box Count', data: history_only('box') }
    ]
  end

  def all_technologies
    return [] if is_a?(Technology)

    # .technologies finds direct relations through Assembly, but doesn't include technologies where this part may be deeply nested in components
    Technology.where('quantities ? :key', key: uid)
  end

  def all_technologies_names
    return short_name if is_a?(Technology)

    all_technologies.active&.pluck(:short_name)&.join(', ')
  end

  def all_technologies_ids
    return id if is_a?(Technology)

    all_technologies.active&.pluck(:id)&.join(',')
  end

  def label_hash
    {
      name: name,
      description: description,
      uid: uid,
      technologies: all_technologies_names,
      quantity_per_box: quantity_per_box,
      picture: picture,
      only_loose: only_loose?
    }
  end

  def picture
    if image.attached?
      image
    else
      'http://placekitten.com/140/140'
    end
  end

  def quantity(item_uid)
    quantities[item_uid]
  end

  def check_uid
    update_columns(uid: "#{self.class.to_s[0]}#{id.to_s.rjust(3, '0')}") if uid.blank? || id != uid[1..].to_i
  end
end
