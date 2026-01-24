# frozen_string_literal: true

# == Schema Information
#
# Table name: bairros
#
#  id         :bigint           not null, primary key
#  latitude   :decimal(, )
#  longitude  :decimal(, )
#  nome       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  cidade_id  :bigint
#
# Indexes
#
#  index_bairros_on_cidade_id  (cidade_id)
#
# Foreign Keys
#
#  fk_rails_...  (cidade_id => cidades.id)
#

class Bairro < ApplicationRecord
  belongs_to :cidade
  has_one :estado, through: :cidade

  has_many :logradouros, dependent: :restrict_with_error
  has_many :assinantes,
           -> { merge(Pessoa.assinantes) },
           through: :logradouros,
           source: :pessoas
  has_many :conexoes, through: :assinantes

  geocoded_by :nome_cidade_uf
  after_validation :geocode, if: :should_geocode?

  RANSACKABLE_ATTRIBUTES = %w[nome].freeze

  def nome_cidade_uf
    "#{nome} - #{cidade.nome_uf}"
  end

  def self.ransackable_attributes(_auth_object = nil)
    RANSACKABLE_ATTRIBUTES
  end

  private

  def should_geocode?
    nome_changed? || cidade_id_changed?
  end
end
