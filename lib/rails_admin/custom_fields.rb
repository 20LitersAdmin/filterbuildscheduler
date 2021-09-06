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

class HistoryJson < RailsAdmin::Config::Fields::Base
  RailsAdmin::Config::Fields::Types.register(:history_json, self)

  register_instance_option :formatted_value do
    html_response = ['<ul>']
    value.reverse_each do |date, quantities|
      html_response << "<li>#{date}: "
      html_response << "#{quantities['loose']} loose; #{quantities['box']} box</li>"
    end
    html_response << ['</ul>']

    html_response.join('').html_safe
  end
end
