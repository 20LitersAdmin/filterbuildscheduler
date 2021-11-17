# frozen_string_literal: true

class SpecGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  argument :spec_name, type: :string
  argument :spec_type, type: :string, default: 'system'

  def generate_spec
    template 'spec.rb', "spec/#{spec_type}/#{file_name}_spec.rb"
  end

  private

  def file_name
    spec_name.underscore
  end

  def human_string
    spec_name.underscore.humanize
  end
end
