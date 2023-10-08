# frozen_string_literal: true

class CreateFibraRedes < ActiveRecord::Migration[5.2]
  def change
    create_table :fibra_redes do |t|
      t.string :nome
      t.references :ponto, foreign_key: true

      t.timestamps
    end
  end
end
