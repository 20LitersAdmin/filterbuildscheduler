# frozen_string_literal: true

module CleanupCrew
  def clean_up!
    # This cannot be allowed to run in production
    # I believe it's safe because the require call only exists in RSpec's rails_helper
    abort('The Rails environment isn\'t Test!!!') unless Rails.env.test?

    puts 'CleanupCrew has arrived.'

    # use .destroy_all to fire all callbacks, including deleting ActiveStorage::Attachments via dependent: :purge

    # Should destroy all Registrations via dependent: :destroy
    Event.destroy_all
    #   Should destroy all TechnologiesUser via HABTM
    User.destroy_all

    # Event requires a location, Events must be destroyed first
    Location.destroy_all

    # Should destroy all Counts via dependent: :destroy
    Inventory.destroy_all

    # Should destroy all Assemblies via dependent: :destroy
    Component.destroy_all
    Part.destroy_all
    Material.destroy_all
    #   Should destroy all TechnologiesUser via HABTM
    Technology.destroy_all

    # Should destroy all Emails via dependent: :destroy
    OauthUser.destroy_all

    # use .delete_all because there are no dependencies
    Supplier.delete_all
    ConstituentEmail.delete_all
    ConstituentPhone.delete_all
    Constituent.delete_all

    # To clear all workers' jobs:
    Sidekiq::Worker.clear_all

    puts 'Mess is gone, boss.'

    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end

    puts 'Lights are off, doors are locked. Good night.'
  end

  module_function :clean_up!
end
