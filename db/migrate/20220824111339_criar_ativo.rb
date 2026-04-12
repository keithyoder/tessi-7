# frozen_string_literal: true

class CriarAtivo < ActiveRecord::Migration[5.2]
  def change
    add_column :planos, :ativo, :boolean, default: true, null: false
    add_column :pagamento_perfis, :ativo, :boolean, default: true, null: false
  end
end
