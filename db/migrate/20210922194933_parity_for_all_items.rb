# frozen_string_literal: true

class ParityForAllItems < ActiveRecord::Migration[6.1]
  def change
    remove_column :components, :completed_tech, :boolean
    remove_column :components, :sample_size, :integer
    remove_column :components, :sample_weight, :float
    remove_column :components, :tare_weight, :float, default: 0.0

    remove_column :parts, :sample_size, :integer
    remove_column :parts, :sample_weight, :float

    ImageSyncJob.perform_now

    remove_column :locations, :photo_url, :string
    remove_column :technologies, :img_url, :string
  end
end
