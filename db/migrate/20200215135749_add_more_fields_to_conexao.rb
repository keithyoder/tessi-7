# frozen_string_literal: true

class AddMoreFieldsToConexao < ActiveRecord::Migration[5.2]
  def change
    add_column :conexoes, :mac, :string
    add_column :conexoes, :tipo, :integer
  end
end
