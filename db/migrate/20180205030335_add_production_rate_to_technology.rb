class AddProductionRateToTechnology < ActiveRecord::Migration[5.1]
  def change
    add_column :technologies, :monthly_production_rate, :integer, default: 1, null: false
  end
end
