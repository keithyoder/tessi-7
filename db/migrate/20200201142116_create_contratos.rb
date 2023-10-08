# frozen_string_literal: true

class CreateContratos < ActiveRecord::Migration[5.2]
  def change
    create_table :contratos do |t|
      t.references :pessoa, foreign_key: true, null: false
      t.references :plano, foreign_key: true, null: false
      t.integer :status
      t.integer :dia_vencimento
      t.date :adesao
      t.decimal :valor_instalacao, precision: 8, scale: 2
      t.integer :numero_conexoes, default: 1
      t.date :cancelamento
      t.boolean :emite_nf, default: true
      t.date :primeiro_vencimento
      t.integer :prazo_meses, default: 12

      t.timestamps
    end
  end
end
