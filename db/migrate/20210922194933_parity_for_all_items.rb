class ParityForAllItems < ActiveRecord::Migration[6.1]
  def change

    # Never trigger an analyzer when calling methods on ActiveStorage
    ActiveStorage::Blob::Analyzable.module_eval do
      def analyze_later; end

      def analyzed?
        true
      end
    end

    add_column :components, :minimum_on_hand, :integer, default: 0, null: false

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
