# frozen_string_literal: true

class AddAssinaturaToContrato < ActiveRecord::Migration[5.2]
  def change
    change_table :contratos, bulk: true do |t|
      t.integer :gerencianet_assinatura_id
      t.string :cartao_parcial
      t.string :billing_nome_completo
      t.string :billing_cpf
      t.string :billing_endereco
      t.string :billing_endereco_numero
      t.string :billing_bairro
      t.string :billing_cidade
      t.string :billing_estado
      t.string :billing_cep
      t.jsonb :documentos
    end
  end
end
