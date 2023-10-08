# frozen_string_literal: true

class CreateOs < ActiveRecord::Migration[5.2]
  def change
    create_table :os do |t|
      t.integer :tipo
      t.references :classificacao, foreign_key: true
      t.references :pessoa, foreign_key: true
      t.references :conexao, foreign_key: true
      t.references :aberto_por, foreign_key: { to_table: :users }
      t.references :responsavel, foreign_key: { to_table: :users }
      t.references :tecnico_1, foreign_key: { to_table: :users }
      t.references :tecnico_2, foreign_key: { to_table: :users }
      t.timestamp :fechamento
      t.text :descricao
      t.text :encerramento

      t.timestamps
    end
  end
end
