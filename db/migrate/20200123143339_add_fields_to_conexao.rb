# frozen_string_literal: true

class AddFieldsToConexao < ActiveRecord::Migration[5.2]
  def change
    change_table :conexoes, bulk: true do |t|
      t.string :observacao
      t.string :usuario
      t.string :senha
    end
  end
end
