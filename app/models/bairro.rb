# frozen_string_literal: true

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
