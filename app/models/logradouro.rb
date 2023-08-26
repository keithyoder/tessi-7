# frozen_string_literal: true

require 'csv'

class Logradouro < ApplicationRecord
  belongs_to :bairro
  has_one :cidade, through: :bairro
  has_one :estado, through: :cidade
  has_many :pessoas
  has_many :assinantes, -> { assinantes }, class_name: 'Pessoa'
  has_many :conexoes, through: :pessoas
  has_many :fibra_caixas

  def endereco
    "#{nome} - #{bairro.nome_cidade_uf}"
  end
end
