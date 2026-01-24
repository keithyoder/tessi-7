# frozen_string_literal: true

# == Schema Information
#
# Table name: os
#
#  id               :bigint           not null, primary key
#  descricao        :text
#  encerramento     :text
#  fechamento       :datetime
#  tipo             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  aberto_por_id    :bigint
#  classificacao_id :bigint
#  conexao_id       :bigint
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
#  fk_rails_...  (pessoa_id => pessoas.id)
#  fk_rails_...  (responsavel_id => users.id)
#  fk_rails_...  (tecnico_1_id => users.id)
#  fk_rails_...  (tecnico_2_id => users.id)
#
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
  enum :tipo, { Instalação: 1, Reparo: 2, Transferência: 3, Retirada: 4 }
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

  def self.ransackable_attributes(_auth_object = nil)
    %w[descricao tipo]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[cidade classificacao conexao estado logradouro pessoa responsavel]
  end
end
