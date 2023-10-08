# frozen_string_literal: true

class AddDesconto < ActiveRecord::Migration[5.2]
  def change
    add_column :planos, :desconto, :decimal, precision: 8, scale: 2
    change_column :faturas, :nossonumero, :string
  end
end
