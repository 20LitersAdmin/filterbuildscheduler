class AddUrlToTechnology < ActiveRecord::Migration[5.1]
  def change
  	change_table :technologies do |t|
  		t.string :img_url
  		t.string :info_url
  	end
  end
end
