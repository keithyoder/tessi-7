# frozen_string_literal: true

class AdicionarLatLonAServidoresEPontos < ActiveRecord::Migration[7.1]
  def change
    change_table :servidores, bulk: true do |t|
      t.column :latitude, :decimal, precision: 10, scale: 6
      t.column :longitude, :decimal, precision: 10, scale: 6
    end

    change_table :pontos, bulk: true do |t|
      t.column :latitude, :decimal, precision: 10, scale: 6
      t.column :longitude, :decimal, precision: 10, scale: 6
    end
  end
end
