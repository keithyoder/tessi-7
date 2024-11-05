# frozen_string_literal: true

# == Schema Information
#
# Table name: atendimentos
#
#  id               :bigint           not null, primary key
#  fechamento       :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  classificacao_id :bigint
#  conexao_id       :bigint
#  contrato_id      :bigint
#  fatura_id        :bigint
#  pessoa_id        :bigint
#  responsavel_id   :bigint
#
# Indexes
#
#  index_atendimentos_on_classificacao_id  (classificacao_id)
#  index_atendimentos_on_conexao_id        (conexao_id)
#  index_atendimentos_on_contrato_id       (contrato_id)
#  index_atendimentos_on_fatura_id         (fatura_id)
#  index_atendimentos_on_pessoa_id         (pessoa_id)
#  index_atendimentos_on_responsavel_id    (responsavel_id)
#
# Foreign Keys
#
#  fk_rails_...  (classificacao_id => classificacoes.id)
#  fk_rails_...  (conexao_id => conexoes.id) ON DELETE => nullify
#  fk_rails_...  (contrato_id => contratos.id)
#  fk_rails_...  (fatura_id => faturas.id)
#  fk_rails_...  (pessoa_id => pessoas.id)
#  fk_rails_...  (responsavel_id => users.id)
#
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
