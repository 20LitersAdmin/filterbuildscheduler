# frozen_string_literal: true

class String
  def objectify_uid
    return if match(Constants::UID::REGEX).nil?

    begin
      case self[0]
      when 'C'
        Component.find(self[1..])
      when 'M'
        Material.find(self[1..])
      when 'P'
        Part.find(self[1..])
      when 'T'
        Technology.find(self[1..])
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
