# frozen_string_literal: true

class CreatePontos < ActiveRecord::Migration[5.2]
  def change
    create_table :pontos do |t|
      t.string :nome
      t.integer :sistema
      t.integer :tecnologia
      t.references :servidor, foreign_key: true
      t.inet :ip
      t.string :usuario
      t.string :senha

      t.timestamps
    end
  end
end
