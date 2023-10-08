# frozen_string_literal: true

class CreateFibraCaixas < ActiveRecord::Migration[5.2]
  def change
    create_table :fibra_caixas do |t|
      t.string :nome
      t.references :fibra_rede, foreign_key: true
      t.integer :capacidade

      t.timestamps
    end
  end
end
