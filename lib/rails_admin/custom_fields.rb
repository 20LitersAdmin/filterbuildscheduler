# frozen_string_literal: true

class DelimitedNumber < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:delimited, self)

  register_instance_option :formatted_value do
    integer = value.instance_of?(String) ? value.to_i : value

    if integer.nil? || integer.zero?
      '-'
    else
      extend ActionView::Helpers::NumberHelper

      number_with_delimiter(integer, delimiter: ',')
    end
  end
end

class FalseIsInvisible < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:false_is_invisible, self)

  register_instance_option :formatted_value do
    case value
    when nil
      %(<span class='label label-default'>&#x2012;</span>)
    when false
      %(&nbsp)
    when true
      %(<span class='label label-success'>&#x2713;</span>)
    end.html_safe
  end
end

class TrueIsBad < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:true_is_bad, self)

  register_instance_option :formatted_value do
    case value
    when nil
      %(<span class='label label-default'>&#x2012;</span>)
    when false
      %(&nbsp)
    when true
      %(<span class='label label-danger'>&#x2713;</span>)
    end.html_safe
  end
end

class TrueIsBadFalseIsGood < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:true_is_bad_false_is_good, self)

  register_instance_option :formatted_value do
    case value
    when nil
      %(<span class='label label-default'>&#x2012;</span>)
    when false
      %(<span class='label label-success'>&#x2718;</span>)
    when true
      %(<span class='label label-danger'>&#x2713;</span>)
    end.html_safe
  end
end

class HistoryJson < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:history_json, self)

  register_instance_option :formatted_value do
    html_response = ['<ul>']
    value.reverse_each do |date, hash|
      html_response << "<li>#{date}: #{hash['available']}</li>"
    end
    html_response << ['</ul>']

    html_response.join.html_safe
  end
end

class QuantitiesJson < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:quantities_json, self)

  register_instance_option :formatted_value do
    html_response = ['<ul>']
    value.each do |uid, quantity|
      item = uid.objectify_uid
      html_response << "<li>#{item.uid_and_name}: #{quantity}</li>"
    end
    html_response << ['</ul>']

    html_response.join.html_safe
  end
end

class HistoryLineChart < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:line_chart, self)

  register_instance_option :formatted_value do
    extend Chartkick::Helper

    line_chart value, curve: false, width: '600px', label: 'Available', thousands: ',', colors: ['#FCE000', '#9BB4C8', '#4A4A4A']
  end
end
