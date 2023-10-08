# frozen_string_literal: true

class CreatePlanos < ActiveRecord::Migration[5.2]
  def change
    create_table :planos do |t|
      t.string :nome
      t.decimal :mensalidade, precision: 8, scale: 2
      t.integer :upload
      t.integer :download
      t.boolean :burst

      t.timestamps
    end
  end
end
