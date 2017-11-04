class ConsentToWaiver < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :signed_consent_form_on, :signed_waiver_on
  end
end
