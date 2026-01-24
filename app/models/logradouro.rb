# frozen_string_literal: true

# == Schema Information
#
# Table name: logradouros
#
#  id         :bigint           not null, primary key
#  cep        :string
#  nome       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  bairro_id  :bigint
#
# Indexes
#
#  index_logradouros_on_bairro_id  (bairro_id)
#
# Foreign Keys
#
#  fk_rails_...  (bairro_id => bairros.id)
#

class Logradouro < ApplicationRecord
  belongs_to :bairro
  has_one :cidade, through: :bairro
  has_one :estado, through: :cidade

  has_many :pessoas, dependent: :restrict_with_error
  has_many :assinantes,
           -> { merge(Pessoa.assinantes) },
           class_name: 'Pessoa',
           foreign_key: :logradouro_id,
           dependent: false,
           inverse_of: :logradouro
  has_many :fibra_caixas, dependent: :restrict_with_error

  RANSACKABLE_ATTRIBUTES = %w[nome].freeze

  def endereco
    "#{nome} - #{bairro.nome_cidade_uf}"
  end

  def conexoes
    Conexao.para_logradouro(id)
  end

  def self.ransackable_attributes(_auth_object = nil)
    RANSACKABLE_ATTRIBUTES
  end
end
