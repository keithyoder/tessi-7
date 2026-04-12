# frozen_string_literal: true

class ChangeIdExternoToString < ActiveRecord::Migration[7.2]
  def up
    change_column :faturas, :id_externo, :string
  end

  def down
    change_column :faturas, :id_externo, :integer
  end
end
