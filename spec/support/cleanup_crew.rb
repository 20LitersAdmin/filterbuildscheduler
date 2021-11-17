# frozen_string_literal: true

module CleanupCrew
  def clean_up!
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
    Organization.delete_all
    Delayed::Job.delete_all

    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  end
end
