# frozen_string_literal: true

class AddFieldsToConexao < ActiveRecord::Migration[5.2]
  def change
    add_column :conexoes, :observacao, :string
    add_column :conexoes, :usuario, :string
    add_column :conexoes, :senha, :string
  end
end
