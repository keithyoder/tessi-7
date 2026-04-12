# frozen_string_literal: true

class CustomContrato < ActiveRecord::Migration[5.2]
  def change
    change_table :contratos, bulk: true do |t|
      t.string :descricao_personalizada
      t.decimal :valor_personalizado, precision: 8, scale: 2
    end
  end
end
