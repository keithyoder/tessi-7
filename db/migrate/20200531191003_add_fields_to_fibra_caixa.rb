# frozen_string_literal: true

class AddFieldsToFibraCaixa < ActiveRecord::Migration[5.2]
  def change
    add_reference :fibra_caixas, :logradouro
    add_column :fibra_caixas, :poste, :string
    add_column :fibra_caixas, :latitude, :decimal, precision: 10, scale: 6
    add_column :fibra_caixas, :longitude, :decimal, precision: 10, scale: 6
  end
end
