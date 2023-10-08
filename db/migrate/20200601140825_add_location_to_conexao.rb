# frozen_string_literal: true

class AddLocationToConexao < ActiveRecord::Migration[5.2]
  def change
    add_column :conexoes, :latitude, :decimal, precision: 10, scale: 6
    add_column :conexoes, :longitude, :decimal, precision: 10, scale: 6
  end
end
