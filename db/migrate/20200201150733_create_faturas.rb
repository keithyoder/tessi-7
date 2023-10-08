# frozen_string_literal: true

class CreateFaturas < ActiveRecord::Migration[5.2]
  def change
    create_table :faturas do |t|
      t.references :contrato, foreign_key: true
      t.decimal :valor, null: false
      t.date :vencimento, null: false
      t.integer :nossonumero, null: false
      t.integer :parcela, null: false
      t.string :arquivo_remessa
      t.date :data_remessa
      t.date :data_cancelamento

      t.timestamps
    end
  end
end
