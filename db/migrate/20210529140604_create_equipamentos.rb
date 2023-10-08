# frozen_string_literal: true

class CreateEquipamentos < ActiveRecord::Migration[5.2]
  def change
    create_table :equipamentos do |t|
      t.string :fabricante
      t.string :modelo
      t.integer :tipo

      t.timestamps
    end
  end
end
