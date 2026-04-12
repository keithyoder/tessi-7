# frozen_string_literal: true

# == Schema Information
#
# Table name: contratos
#
#  id                      :bigint           not null, primary key
#  adesao                  :date
#  billing_bairro          :string
#  billing_cep             :string
#  billing_cidade          :string
#  billing_cpf             :string
#  billing_endereco        :string
#  billing_endereco_numero :string
#  billing_estado          :string
#  billing_nome_completo   :string
#  cancelamento            :date
#  cartao_parcial          :string
#  descricao_personalizada :string
#  dia_vencimento          :integer
#  documentos              :jsonb
#  emite_nf                :boolean          default(TRUE)
#  numero_conexoes         :integer          default(1)
#  parcelas_instalacao     :integer
#  prazo_meses             :integer          default(12)
#  primeiro_vencimento     :date
#  status                  :integer
#  valor_instalacao        :decimal(8, 2)
#  valor_personalizado     :decimal(8, 2)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  pagamento_perfil_id     :bigint
#  pessoa_id               :bigint           not null
#  plano_id                :bigint           not null
#  recorrencia_id          :string
#
# Indexes
#
#  index_contratos_on_pagamento_perfil_id  (pagamento_perfil_id)
#  index_contratos_on_pessoa_id            (pessoa_id)
#  index_contratos_on_plano_id             (plano_id)
#
# Foreign Keys
#
#  fk_rails_...  (pagamento_perfil_id => pagamento_perfis.id)
#  fk_rails_...  (pessoa_id => pessoas.id)
#  fk_rails_...  (plano_id => planos.id)
#
module ContratosHelper
  def autentique_status(eventos)
    return 'visualizado' if eventos['opened'].present?
    return 'recebido' if eventos['delivered'].present?

    'enviado' if eventos['sent'].present?
  end
end
