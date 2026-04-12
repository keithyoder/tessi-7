# frozen_string_literal: true

class AddLocationToConexao < ActiveRecord::Migration[5.2]
  def change
    change_table :conexoes, bulk: true do |t|
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
    end
  end
end
