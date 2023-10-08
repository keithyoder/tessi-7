# frozen_string_literal: true

class CreateNf21s < ActiveRecord::Migration[5.2]
  def change
    create_table :nf21s do |t|
      t.references :fatura
      t.date :emissao
      t.integer :numero
      t.decimal :valor, precision: 8, scale: 2
      t.text :cadastro
      t.text :mestre

      t.timestamps
    end
  end
end
