# frozen_string_literal: true

class String
  # result like Component.find(22)
  def objectify_uid
    uid_eval = evaluate_uid

    uid_eval[0].constantize.find(uid_eval[1])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # result like ['Component', 22]
  def evaluate_uid
    return unless match(Constants::UID::REGEX).present?

    [Constants::UID::CHAR[self[0].to_sym], self[1..].to_i]
  end
end
