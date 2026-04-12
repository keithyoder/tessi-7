# frozen_string_literal: true

class AddNameToUser < ActiveRecord::Migration[5.2]
  def change
    change_table :users, bulk: true do |t|
      t.string :primeiro_nome
      t.string :nome_completo
    end
  end
end
