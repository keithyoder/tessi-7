# frozen_string_literal: true

class AddNameToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :primeiro_nome, :string
    add_column :users, :nome_completo, :string
  end
end
