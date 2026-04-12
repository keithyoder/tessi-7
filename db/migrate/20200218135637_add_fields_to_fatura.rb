# frozen_string_literal: true

class AddFieldsToFatura < ActiveRecord::Migration[5.2]
  def change
    change_table :faturas, bulk: true do |t|
      t.decimal :juros_recebidos
      t.decimal :desconto_concedido
      t.integer :banco
      t.integer :agencia
    end
  end
end
