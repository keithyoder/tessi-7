# frozen_string_literal: true

class AddFieldsToFibraCaixa < ActiveRecord::Migration[5.2]
  def change
    add_reference :fibra_caixas, :logradouro
    change_table :fibra_caixas, bulk: true do |t|
      t.string :poste
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
    end
  end
end
