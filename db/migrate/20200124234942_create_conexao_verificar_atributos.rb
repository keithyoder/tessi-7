# frozen_string_literal: true

class CreateConexaoVerificarAtributos < ActiveRecord::Migration[5.2]
  def change
    create_table :conexao_verificar_atributos do |t|
      t.references :conexao, foreign_key: true
      t.string :atributo
      t.string :op
      t.string :valor

      t.timestamps
    end
  end
end
