# frozen_string_literal: true

module ApplicationHelper
  def bootstrap_class_for(flash_type)
    h = {
      success: "success",
      danger: "danger",
      error: "danger",
      warning: "warning",
      alert: "warning",
      notice: "warning"
    }
    return h[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
              concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
              concat message
            end)
      end
    nil
  end

  def pluralize_without_count(count, noun, text = nil)
    return unless count != 0

    count == 1 ? "#{noun}#{text}" : "#{noun.pluralize}#{text}"
  end

  def human_float(float, precision = 2)
    float.round(precision)
  end

  def human_boolean(boolean)
    boolean ? 'Yes' : 'No'
  end

  def human_number(integer)
    return '-' if integer.nil? || integer.zero?

    number_with_delimiter(integer, delimiter: ',')
  end

  def human_date(date_or_datetime)
    return '-' if date_or_datetime.nil?

    date_or_datetime.strftime('%-m/%-d/%y')
  end

  def human_datetime(datetime)
    return '-' if date_or_datetime.nil?

    datetime.strftime('%-m/%-d/%y %l:%M')
  end
end
