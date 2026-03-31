# frozen_string_literal: true

# db/migrate/YYYYMMDDHHMMSS_add_substituicao_to_nfcom_notas.rb
class AddSubstituicaoToNfcomNotas < ActiveRecord::Migration[7.2]
  def change
    add_column :nfcom_notas, :nota_substituida_id, :bigint
    add_column :nfcom_notas, :motivo_substituicao, :string, limit: 2
    add_index  :nfcom_notas, :nota_substituida_id

    add_foreign_key :nfcom_notas, :nfcom_notas,
                    column: :nota_substituida_id
  end
end
