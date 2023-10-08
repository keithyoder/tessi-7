# frozen_string_literal: true

class CreateCidades < ActiveRecord::Migration[5.2]
  def change
    create_table :cidades do |t|
      t.string :nome
      t.references :estado, foreign_key: true
      t.string :ibge

      t.timestamps
    end
  end
end
