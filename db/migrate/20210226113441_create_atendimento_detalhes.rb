# frozen_string_literal: true

class CreateAtendimentoDetalhes < ActiveRecord::Migration[5.2]
  def change
    create_table :atendimento_detalhes do |t|
      t.references :atendimento, foreign_key: true
      t.integer :tipo
      t.references :atendente, foreign_key: { to_table: :users }
      t.text :descricao

      t.timestamps
    end
  end
end
