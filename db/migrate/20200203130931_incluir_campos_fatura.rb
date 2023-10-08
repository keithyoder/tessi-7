# frozen_string_literal: true

class IncluirCamposFatura < ActiveRecord::Migration[5.2]
  def change
    add_column :faturas, :liquidacao, :date
    add_column :faturas, :valor_liquidacao, :decimal, precision: 8, scale: 2
    add_column :faturas, :vencimento_original, :date
    add_column :faturas, :valor_original, :decimal, precision: 8, scale: 2
    add_column :faturas, :meio_liquidacao, :integer
    add_column :faturas, :periodo_inicio, :date
    add_column :faturas, :periodo_fim, :date
  end
end
