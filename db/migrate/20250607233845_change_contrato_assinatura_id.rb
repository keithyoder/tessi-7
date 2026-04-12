# frozen_string_literal: true

# This migration removes the old `gerencianet_assinatura_id` column
# and adds a new `recorrencia_id` column.
class ChangeContratoAssinaturaId < ActiveRecord::Migration[7.2]
  def change
    change_table :contratos, bulk: true do |t|
      t.remove :gerencianet_assinatura_id, type: :integer
      t.string :recorrencia_id, null: true
    end
  end
end
