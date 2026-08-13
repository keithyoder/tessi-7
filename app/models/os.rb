# frozen_string_literal: true

# == Schema Information
#
# Table name: os
#
#  id               :bigint           not null, primary key
#  agendado_em      :date
#  descricao        :text
#  encerramento     :text
#  fechamento       :datetime
#  resultado        :integer
#  tipo             :integer
#  vezes_reagendada :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  aberto_por_id    :bigint
#  classificacao_id :bigint
#  conexao_id       :bigint
#  os_origem_id     :bigint
#  pessoa_id        :bigint
#  responsavel_id   :bigint
#  tecnico_1_id     :bigint
#  tecnico_2_id     :bigint
#
# Indexes
#
#  index_os_on_aberto_por_id     (aberto_por_id)
#  index_os_on_classificacao_id  (classificacao_id)
#  index_os_on_conexao_id        (conexao_id)
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
  belongs_to :pessoa
  has_one :logradouro, through: :pessoa
  has_one :bairro, through: :pessoa
  has_one :cidade, through: :pessoa
  has_one :estado, through: :pessoa
  belongs_to :conexao, optional: true
  belongs_to :aberto_por, class_name: 'User'
  belongs_to :responsavel, class_name: 'User'
  belongs_to :tecnico_1, class_name: 'User', optional: true
  belongs_to :tecnico_2, class_name: 'User', optional: true
  enum :tipo, { Instalação: 1, Reparo: 2, Transferência: 3, Retirada: 4 }
  scope :abertas, -> { where(fechamento: nil) }
  scope :fechadas, -> { where.not(fechamento: nil) }
  scope :por_responsavel, ->(responsavel) { where(responsavel: responsavel) }
  scope :cidade, ->(cidade_id) { joins(:pessoa, :logradouro, :bairro, :cidade).where(cidades: { id: cidade_id }) }
  validates :tipo, :descricao, presence: true
  validates :conexao, presence: true, if: :reparo?
  validate :tecnicos_diferentes

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

  def endereco_estimado
    return conexao.endereco if conexao.present?

    [pessoa.endereco.presence, pessoa.bairro&.nome_cidade_uf].compact.join(' - ')
  end
end
