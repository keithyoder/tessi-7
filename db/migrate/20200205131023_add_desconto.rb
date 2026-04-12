# frozen_string_literal: true

class AddDesconto < ActiveRecord::Migration[5.2]
  def up
    add_column :planos, :desconto, :decimal, precision: 8, scale: 2
    change_column :faturas, :nossonumero, :string
  end

  def down
    remove_column :planos, :desconto
  end
end
