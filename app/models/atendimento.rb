# frozen_string_literal: true

class Atendimento < ApplicationRecord
  belongs_to :pessoa
  belongs_to :classificacao
  belongs_to :responsavel, class_name: 'User'
  belongs_to :contrato, optional: true
  belongs_to :conexao, optional: true
  belongs_to :fatura, optional: true
  has_many :detalhes, class_name: 'AtendimentoDetalhe'

  scope :abertos, -> { where(fechamento: nil) }
  scope :fechados, -> { where.not(fechamento: nil) }
  scope :por_responsavel, ->(responsavel) { where(responsavel:) }

  attr_accessor :detalhe_tipo, :detalhe_atendente, :detalhe_descricao

  def self.ransackable_attributes(_auth_object = nil)
    %w[fechamento id pessoa_id responsavel_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[classificacao conexao contrato detalhes fatura pessoa responsavel]
  end
end
