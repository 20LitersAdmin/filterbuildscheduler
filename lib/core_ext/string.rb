# frozen_string_literal: true

class String
  def objectify_uid
    return unless match(Constants::UID::REGEX).present?

    Constants::UID::CHAR[self[0].to_sym].constantize.find(self[1..])
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
