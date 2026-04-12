# frozen_string_literal: true

# db/migrate/YYYYMMDDHHMMSS_add_substituicao_to_nfcom_notas.rb
class AddSubstituicaoToNfcomNotas < ActiveRecord::Migration[7.2]
  def change
    change_table :nfcom_notas, bulk: true do |t|
      t.bigint :nota_substituida_id
      t.string :motivo_substituicao, limit: 2
    end
    add_index :nfcom_notas, :nota_substituida_id

    add_foreign_key :nfcom_notas, :nfcom_notas,
                    column: :nota_substituida_id
  end
end
