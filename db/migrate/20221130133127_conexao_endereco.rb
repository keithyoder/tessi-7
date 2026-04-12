# frozen_string_literal: true

class ConexaoEndereco < ActiveRecord::Migration[5.2]
  def change
    add_reference :conexoes, :logradouro, foreign_key: true
    change_table :conexoes, bulk: true do |t|
      t.string :numero
      t.string :complemento
    end
  end
end
