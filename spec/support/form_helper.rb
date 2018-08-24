# frozen_string_literal: true

module FormHelper
  def click_submit(input_name="commit")
    find('input[name="' + input_name + '"]').click
  end
end
