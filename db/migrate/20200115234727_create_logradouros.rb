# frozen_string_literal: true

class CreateLogradouros < ActiveRecord::Migration[5.2]
  def change
    create_table :logradouros do |t|
      t.string :nome
      t.references :bairro, foreign_key: true
      t.string :cep

      t.timestamps
    end
  end
end
