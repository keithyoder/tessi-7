# frozen_string_literal: true

class CreateClassificacoes < ActiveRecord::Migration[5.2]
  def change
    create_table :classificacoes do |t|
      t.integer :tipo
      t.string :nome

      t.timestamps
    end
  end
end
