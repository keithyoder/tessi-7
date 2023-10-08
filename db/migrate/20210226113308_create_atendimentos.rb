# frozen_string_literal: true

class CreateAtendimentos < ActiveRecord::Migration[5.2]
  def change
    create_table :atendimentos do |t|
      t.references :pessoa, foreign_key: true
      t.references :classificacao, foreign_key: true
      t.references :responsavel, foreign_key: { to_table: :users }
      t.datetime :fechamento
      t.references :contrato, foreign_key: true
      t.references :conexao, foreign_key: true
      t.references :fatura, foreign_key: true

      t.timestamps
    end
  end
end
