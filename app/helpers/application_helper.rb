# frozen_string_literal: true

module ApplicationHelper
  def bootstrap_class_for(flash_type)
    h = {
      success: 'success',
      danger: 'danger',
      error: 'danger',
      warning: 'warning',
      alert: 'warning',
      notice: 'warning'
    }

    h[flash_type.to_sym] || flash_type.to_s
  end

  def date_for_form(date = Date.today)
    date.to_date.iso8601
  end

  def flash_messages(_opts = {})
    flash.each do |msg_type, message|
      concat(
        content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
          concat content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
          concat message
        end
      )
    end
    nil
  end

  def human_float(float, precision = 2)
    return '-' if float.nil? || float.zero?

    number_with_delimiter(float.round(precision), delimiter: ',')
  end

  def human_boolean(boolean)
    boolean ? 'Yes' : 'No'
  end

  def human_number(number)
    integer = number.instance_of?(String) ? number.to_i : number

    return '-' if integer.nil? || integer.zero?

    number_with_delimiter(integer, delimiter: ',')
  end

  def human_date(date_or_datetime)
    return '-' if date_or_datetime.nil?

    date = date_or_datetime.instance_of?(String) ? Date.parse(date_or_datetime) : date_or_datetime

    date.strftime('%-m/%-d/%y')
  end

  def human_datetime(date_or_datetime)
    return '-' if date_or_datetime.nil?

    time = date_or_datetime.instance_of?(String) ? Time.parse(date_or_datetime) : date_or_datetime

    time.strftime('%-m/%-d/%y %l:%M %P')
  end

  def human_month_year(date_or_datetime)
    return '-' if date_or_datetime.nil?

    date_or_datetime.strftime('%b, %Y')
  end

  def pluralize_without_count(count, noun, text = nil)
    return if count.zero?

    count == 1 ? "#{noun}#{text}" : "#{noun.pluralize}#{text}"
  end

  def time_for_form(time)
    if time.present?
      time.to_time.iso8601
    else
      Time.now.iso8601
    end
  end
end
