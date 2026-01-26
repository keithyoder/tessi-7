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
class Contrato < ApplicationRecord
  belongs_to :pessoa
  belongs_to :plano
  belongs_to :pagamento_perfil
  has_many :faturas, dependent: :delete_all
  has_many :conexoes
  has_many :excecoes, dependent: :delete_all

  # --------------------
  # SCOPES
  # --------------------
  scope :disponiveis, lambda {
    where(id: Contrato.select('contratos.id')
      .left_joins(:conexoes)
      .group('contratos.id')
      .having('count(conexoes.*) < contratos.numero_conexoes'))
  }

  scope :ativos, -> { where(cancelamento: nil) }

  scope :suspendiveis, lambda {
    includes(:pessoa)
      .joins(:conexoes, :faturas)
      .where(
        conexoes: { bloqueado: false },
        faturas: { liquidacao: nil, cancelamento: nil }
      )
      .where('faturas.vencimento < ?', 15.days.ago)
      .distinct
  }

  scope :liberaveis, lambda {
    joins(:conexoes)
      .joins("LEFT OUTER JOIN faturas ON contratos.id = faturas.contrato_id AND faturas.cancelamento IS NULL AND liquidacao IS NULL AND vencimento < '#{15.days.ago}'")
      .where(
        cancelamento: nil,
        conexoes: { bloqueado: true }
      )
      .group('contratos.id')
      .having('count(faturas.*) = 0')
      .distinct
  }

  scope :cancelaveis, lambda {
    joins(:pessoa, :faturas, :plano)
      .where(faturas: { liquidacao: nil, cancelamento: nil })
      .where('faturas.vencimento < ?', 1.day.ago)
      .group('contratos.id, pessoas.id, planos.id')
      .having('COUNT(faturas.*) > 4')
      .ativos
  }

  scope :renovaveis, lambda {
    joins(:pessoa, :plano)
      .joins("LEFT JOIN faturas ON contratos.id = faturas.contrato_id AND faturas.periodo_fim > '#{15.days.from_now}'")
      .group('contratos.id', 'pessoas.id', 'planos.id')
      .having('COUNT(faturas.*) = 0')
      .ativos
  }

  scope :fisica, -> { joins(:pessoa).where('pessoas.tipo = 1') }
  scope :juridica, -> { joins(:pessoa).where('pessoas.tipo = 2') }
  scope :novos_por_mes, ->(mes) { where("date_trunc('month', adesao) = ?", mes) }

  scope :sem_conexao, lambda {
    joins(:pessoa, :plano)
      .left_outer_joins(:conexoes)
      .group('contratos.id', 'pessoas.id', 'planos.id')
      .having('COUNT(conexoes.*) = 0')
      .ativos
  }

  # --------------------
  # CALLBACKS
  # --------------------
  after_create :gerar_faturas_iniciais
  after_save :after_save
  before_destroy :verificar_exclusao, prepend: true

  # --------------------
  # MÉTODOS PÚBLICOS
  # --------------------
  def faturas_em_atraso(dias)
    prazo = dias.days.ago
    faturas.select { |f| f.liquidacao.nil? && f.cancelamento.nil? && f.vencimento < prazo }.count
  end

  def contrato_e_nome
    "#{id} - #{pessoa.nome}"
  end

  def pix_automatico
    return unless recorrencia_id.present?

    Efi::PixAutomatico.new(self)
  end

  def suspender?
    (faturas_em_atraso(15).positive? && excecoes.validas_para_desbloqueio.none?) || excecoes.validas_para_bloqueio.any?
  end

  def atualizar_conexoes
    suspenso = suspender?
    atraso = faturas_em_atraso(5).positive?
    conexoes.each do |conexao|
      next unless conexao.auto_bloqueio?

      conexao.update!(
        bloqueado: suspenso,
        inadimplente: atraso
      )
    end
  end

  def mensalidade
    valor_personalizado || plano.mensalidade
  end

  def mensalidade_com_desconto
    mensalidade - plano.desconto
  end

  def descricao
    descricao_personalizada.presence || plano.nome
  end

  def ultima_fatura_paga
    @ultima_fatura_paga ||= faturas.pagas.order(:vencimento).last
  end

  def primeira_fatura_em_aberto
    @primeira_fatura_em_aberto ||= faturas.em_aberto.order(:vencimento).first
  end

  def pagou_trocado?
    return false unless ultima_fatura_paga && primeira_fatura_em_aberto

    ultima_fatura_paga.vencimento > primeira_fatura_em_aberto.vencimento
  end

  def self.to_csv
    headers = %i[ID Assinante Plano Adesão Cancelamento]
    CSV.generate(headers: true) do |csv|
      csv << headers

      all.each do |contrato|
        csv << [
          contrato.id,
          contrato.pessoa.nome,
          contrato.plano.nome,
          contrato.adesao,
          contrato.cancelamento
        ]
      end
    end
  end

  def vincular_documento(id)
    require 'autentique'

    documento = Autentique::Client.query(
      Autentique::resgatar_documento,
      variables: { "id": id }
    ).original_hash['data']['document']
    documentos_array = documentos.presence || []
    update(
      documentos: documentos_array + [
        {
          'data' => documento['created_at'],
          'nome' => documento['name'],
          'link' => documento['files']['signed']
        }
      ]
    )
  end

  def endereco_instalacao_diferente?
    conexoes.any? { |conexao| conexao.logradouro.present? }
  end

  def enderecos
    return ["#{pessoa.endereco} - #{pessoa.logradouro.bairro.nome_cidade_uf}"] if conexoes.empty?

    conexoes.map do |conexao|
      if conexao.logradouro.present?
        "#{conexao.logradouro.nome} - #{conexao.logradouro.bairro.nome_cidade_uf}"
      else
        "#{pessoa.endereco} - #{pessoa.logradouro.bairro.nome_cidade_uf}"
      end
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[dia_vencimento pessoas_nome plano_nome]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['pessoas']
  end

  # --------------------
  # MÉTODOS PRIVADOS
  # --------------------
  private

  def gerar_faturas_iniciais
    Faturas::GerarService.call(
      contrato: self,
      quantidade: prazo_meses,
      meses_por_fatura: 1
    )
  end

  def verificar_exclusao
    return if faturas.registradas.none? && faturas.pagas.none?

    errors[:base] << 'Não pode excluir um contrato que tem faturas pagas ou boletos registrados'
    throw :abort
  end

  def after_save
    verificar_cancelamento if saved_change_to_cancelamento?
    alterar_forma_pagamento if saved_change_to_pagamento_perfil_id? || saved_change_to_dia_vencimento?
  end

  def verificar_cancelamento
    CancelamentoService.call(contrato: self)
  end

  def alterar_forma_pagamento
    faturas.a_vencer.nao_registradas.each(&:destroy)
    Contratos::RenovarService.new(contrato: self).call
  end
end
