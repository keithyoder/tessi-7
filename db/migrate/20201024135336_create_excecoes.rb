# frozen_string_literal: true

class CreateExcecoes < ActiveRecord::Migration[5.2]
  def change
    create_table :excecoes do |t|
      t.references :contrato, foreign_key: true
      t.date :valido_ate
      t.integer :tipo
      t.string :usuario

      t.timestamps
    end
  end
end
