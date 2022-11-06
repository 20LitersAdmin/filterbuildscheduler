# frozen_string_literal: true

## =====> Hello, Interviewers!
# My inventory items (Part, Material, Component, Technology)
# have a UID string field that is essentially a SKU-style identifier
# formed by concatentating the first letter of the class and the ID of
# the record.
# Rails' global ID was an option, but not visually as readable for
# user-facing views like labels and reports.
#
# Items are polymorphically associated with each other, which means
# using the UID in some routes and actions becomes a convenient way
# to not have to care what type of item we're dealing with
# But I needed a way to "decode" the UID and find the associated record.
# This little bit of String class hackery offers a helpful method.
#
# Is this an antipattern? An act of defiance to Matz himself? Or actually
# an okay thing to do?
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
