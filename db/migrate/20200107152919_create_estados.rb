# frozen_string_literal: true

class CreateEstados < ActiveRecord::Migration[5.2]
  def change
    create_table :estados do |t|
      t.string :sigla
      t.string :nome
      t.integer :ibge

      t.timestamps
    end
  end
end
