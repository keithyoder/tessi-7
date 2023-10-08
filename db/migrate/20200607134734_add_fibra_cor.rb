# frozen_string_literal: true

class AddFibraCor < ActiveRecord::Migration[5.2]
  def change
    add_column :fibra_caixas, :fibra_cor, :integer
    add_column :fibra_redes, :fibra_cor, :integer
    add_column :pessoas, :latitude, :decimal, precision: 10, scale: 6
    add_column :pessoas, :longitude, :decimal, precision: 10, scale: 6
  end
end
