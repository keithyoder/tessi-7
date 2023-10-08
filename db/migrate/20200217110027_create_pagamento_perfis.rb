# frozen_string_literal: true

class CreatePagamentoPerfis < ActiveRecord::Migration[5.2]
  def change
    create_table :pagamento_perfis do |t|
      t.string :nome
      t.integer :tipo
      t.integer :cedente
      t.integer :agencia
      t.integer :conta
      t.string :carteira

      t.timestamps
    end
  end
end
