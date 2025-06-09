# frozen_string_literal: true

# This migration removes the old `gerencianet_assinatura_id` column
# and adds a new `recorrencia_id` column.
class ChangeContratoAssinaturaId < ActiveRecord::Migration[7.2]
  def change
    # Remove the old column
    remove_column :contratos, :gerencianet_assinatura_id

    # Add the new column with the correct type
    add_column :contratos, :recorrencia_id, :string, null: true
  end
end
