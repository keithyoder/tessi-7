# frozen_string_literal: true

class AddFibraCor < ActiveRecord::Migration[5.2]
  def change
    add_column :fibra_caixas, :fibra_cor, :integer
    add_column :fibra_redes, :fibra_cor, :integer
    change_table :pessoas, bulk: true do |t|
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
    end
  end
end
