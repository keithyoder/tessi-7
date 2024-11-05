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
require 'csv'

class Bairro < ApplicationRecord
  belongs_to :cidade
  has_one :estado, through: :cidade
  has_many :logradouros
  has_many :assinantes,
           -> { assinantes },
           source: :pessoas,
           through: :logradouros

  has_many :conexoes, through: :assinantes
  geocoded_by :nome_cidade_uf
  after_validation :geocode

  def nome_cidade_uf
    "#{nome} - #{cidade.nome_uf}"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["nome"]
  end
end
