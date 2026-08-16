# frozen_string_literal: true

# == Schema Information
#
# Table name: os
#
#  id                  :bigint           not null, primary key
#  agendado_em         :datetime
#  descricao           :text
#  encerramento        :text
#  fechamento          :datetime
#  infraestrutura_type :string
#  resultado           :integer
#  tipo                :integer
#  vezes_reagendada    :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  aberto_por_id       :bigint
#  classificacao_id    :bigint
#  conexao_id          :bigint
#  infraestrutura_id   :bigint
#  os_origem_id        :bigint
#  pessoa_id           :bigint
#  responsavel_id      :bigint
#  tecnico_1_id        :bigint
#  tecnico_2_id        :bigint
#
# Indexes
#
#  index_os_on_aberto_por_id     (aberto_por_id)
#  index_os_on_classificacao_id  (classificacao_id)
#  index_os_on_conexao_id        (conexao_id)
#  index_os_on_infraestrutura    (infraestrutura_type,infraestrutura_id)
#  index_os_on_os_origem_id      (os_origem_id)
#  index_os_on_pessoa_id         (pessoa_id)
#  index_os_on_responsavel_id    (responsavel_id)
#  index_os_on_tecnico_1_id      (tecnico_1_id)
#  index_os_on_tecnico_2_id      (tecnico_2_id)
#
# Foreign Keys
#
#  fk_rails_...  (aberto_por_id => users.id)
#  fk_rails_...  (classificacao_id => classificacoes.id)
#  fk_rails_...  (conexao_id => conexoes.id)
#  fk_rails_...  (os_origem_id => os.id)
#  fk_rails_...  (pessoa_id => pessoas.id)
#  fk_rails_...  (responsavel_id => users.id)
#  fk_rails_...  (tecnico_1_id => users.id)
#  fk_rails_...  (tecnico_2_id => users.id)
#
class Os < ApplicationRecord
  REQUER_REAGENDAMENTO = %w[nao_resolvido cliente_ausente].freeze

  belongs_to :classificacao
  belongs_to :pessoa, optional: true
  belongs_to :infraestrutura, polymorphic: true, optional: true
  has_one :logradouro, through: :pessoa
  has_one :bairro, through: :pessoa
  has_one :cidade, through: :pessoa
  has_one :estado, through: :pessoa
  belongs_to :conexao, optional: true
  belongs_to :aberto_por, class_name: 'User'
  belongs_to :responsavel, class_name: 'User'
  belongs_to :tecnico_1, class_name: 'User', optional: true
  belongs_to :tecnico_2, class_name: 'User', optional: true
  belongs_to :os_origem, class_name: 'Os', optional: true
  has_many :os_reagendadas, class_name: 'Os', foreign_key: :os_origem_id, inverse_of: :os_origem, dependent: :nullify
  scope :abertas, -> { where(fechamento: nil) }
  scope :fechadas, -> { where.not(fechamento: nil) }
  scope :por_responsavel, ->(responsavel) { where(responsavel: responsavel) }
  scope :cidade, ->(cidade_id) { joins(:pessoa, :logradouro, :bairro, :cidade).where(cidades: { id: cidade_id }) }
  validates :tipo, :descricao, presence: true
  validates :conexao, presence: true, if: :reparo?
  validates :resultado, presence: true, if: :fechamento?
  validate :tecnicos_diferentes
  validate :pessoa_ou_infraestrutura

  scope :com_endereco_carregado, lambda {
    includes(
      :infraestrutura,
      pessoa: [
        { logradouro: { bairro: { cidade: :estado } } },
        { bairro: { cidade: :estado } },
        { cidade: :estado }
      ],
      conexao: [
        { logradouro: { bairro: { cidade: :estado } } },
        { pessoa: { logradouro: { bairro: { cidade: :estado } } } }
      ]
    )
  }

  enum :tipo, { Instalação: 1, Reparo: 2, Transferência: 3, Retirada: 4, Infraestrutura: 5 }

  enum :resultado, {
    resolvido: 0,
    sem_problema_encontrado: 1,
    nao_despachado: 2,
    nao_resolvido: 3,
    cliente_ausente: 4
  }

  def reparo?
    tipo == 'Reparo'
  end

  def requer_reagendamento?
    resultado.in?(REQUER_REAGENDAMENTO)
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[abertas cidade]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at descricao fechamento responsavel_id tipo]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cidade classificacao conexao estado logradouro pessoa responsavel]
  end

  def self.adicionar_dias_uteis(datetime, dias)
    resultado = datetime
    dias_adicionados = 0
    while dias_adicionados < dias
      resultado += 1.day
      dias_adicionados += 1 unless resultado.saturday? || resultado.sunday?
    end
    resultado
  end

  def sla_prazo
    return nil if classificacao&.sla_dias.blank?

    Os.adicionar_dias_uteis(created_at, classificacao.sla_dias)
  end

  def sla_status
    return :sem_sla if sla_prazo.nil?

    if fechamento.present?
      fechamento > sla_prazo ? :atrasado : :no_prazo
    elsif Time.current > sla_prazo
      :atrasado
    elsif Time.current > sla_prazo - 1.day
      :em_risco
    else
      :no_prazo
    end
  end

  def tecnicos_diferentes
    return if tecnico_1_id.blank? || tecnico_2_id.blank?

    errors.add(:tecnico_2, 'não pode ser o mesmo que o técnico 1') if tecnico_1_id == tecnico_2_id
  end

  def pessoa_ou_infraestrutura
    if pessoa.blank? && infraestrutura.blank?
      errors.add(:base, 'deve ter um assinante ou uma infraestrutura associada')
    elsif pessoa.present? && infraestrutura.present?
      errors.add(:base, 'não pode ter assinante e infraestrutura associados ao mesmo tempo')
    end
  end

  def endereco_estimado
    return conexao.endereco if conexao.present?
    return infraestrutura.nome if infraestrutura.present?

    [pessoa.endereco.presence, pessoa.bairro&.nome_cidade_uf].compact.join(' - ')
  end

  def link_google_maps
    return conexao.link_google_maps if conexao&.link_google_maps.present?
    return nil unless infraestrutura&.latitude.present? && infraestrutura&.longitude.present?

    "http://maps.google.com/maps?q=#{infraestrutura.latitude},#{infraestrutura.longitude}"
  end
end
