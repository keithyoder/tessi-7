# frozen_string_literal: true

class Os < ApplicationRecord
  belongs_to :classificacao, optional: true
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
  enum tipo: { Instalação: 1, Reparo: 2, Transferência: 3, Retirada: 4 }
  scope :abertas, -> { where(fechamento: nil) }
  scope :fechadas, -> { where.not(fechamento: nil) }
  scope :por_responsavel, ->(responsavel) { where(responsavel: responsavel) }
  scope :cidade, ->(cidade_id) { joins(:pessoa, :logradouro, :bairro, :cidade).where(cidades: { id: cidade_id }) }
  validates :tipo, :descricao, presence: true
  validates :conexao, presence: true, if: :reparo?

  def reparo?
    tipo == 'Reparo'
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[abertas cidade]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["descricao", "tipo"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["cidade", "classificacao", "conexao", "estado", "logradouro", "pessoa", "responsavel"]
  end
end
