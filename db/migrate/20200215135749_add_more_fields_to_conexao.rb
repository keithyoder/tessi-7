# frozen_string_literal: true

class AddMoreFieldsToConexao < ActiveRecord::Migration[5.2]
  def change
    change_table :conexoes, bulk: true do |t|
      t.string :mac
      t.integer :tipo
    end
  end
end
