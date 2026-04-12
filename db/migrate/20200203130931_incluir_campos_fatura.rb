# frozen_string_literal: true

class IncluirCamposFatura < ActiveRecord::Migration[5.2]
  def change
    change_table :faturas, bulk: true do |t|
      t.date :liquidacao
      t.decimal :valor_liquidacao, precision: 8, scale: 2
      t.date :vencimento_original
      t.decimal :valor_original, precision: 8, scale: 2
      t.integer :meio_liquidacao
      t.date :periodo_inicio
      t.date :periodo_fim
    end
  end
end
