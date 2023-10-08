# frozen_string_literal: true

class AddFieldsToFatura < ActiveRecord::Migration[5.2]
  def change
    add_column :faturas, :juros_recebidos, :decimal
    add_column :faturas, :desconto_concedido, :decimal
    add_column :faturas, :banco, :integer
    add_column :faturas, :agencia, :integer
  end
end
