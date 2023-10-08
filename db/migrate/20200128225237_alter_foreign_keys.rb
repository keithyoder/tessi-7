# frozen_string_literal: true

class AlterForeignKeys < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :conexao_enviar_atributos, :conexoes
    add_foreign_key :conexao_enviar_atributos, :conexoes, on_delete: :cascade
    remove_foreign_key :conexao_verificar_atributos, :conexoes
    add_foreign_key :conexao_verificar_atributos, :conexoes, on_delete: :cascade
    remove_foreign_key :plano_enviar_atributos, :planos
    add_foreign_key :plano_enviar_atributos, :planos, on_delete: :cascade
    remove_foreign_key :plano_verificar_atributos, :planos
    add_foreign_key :plano_verificar_atributos, :planos, on_delete: :cascade
    add_index :conexao_verificar_atributos, %i[conexao_id atributo], unique: true
    add_index :conexao_enviar_atributos, %i[conexao_id atributo], unique: true
  end
end
