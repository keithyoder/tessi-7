class AddAssinaturaToContrato < ActiveRecord::Migration[5.2]
  def change
    add_column :contratos, :gerencianet_assinatura_id, :integer
    add_column :contratos, :cartao_parcial, :string
    add_column :contratos, :billing_nome_completo, :string
    add_column :contratos, :billing_cpf, :string
    add_column :contratos, :billing_endereco, :string
    add_column :contratos, :billing_endereco_numero, :string
    add_column :contratos, :billing_bairro, :string
    add_column :contratos, :billing_cidade, :string
    add_column :contratos, :billing_estado, :string
    add_column :contratos, :billing_cep, :string
    add_column :contratos, :documentos, :jsonb
  end
end
