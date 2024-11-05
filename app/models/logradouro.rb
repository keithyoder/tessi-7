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

  def self.ransackable_attributes(auth_object = nil)
    ["nome"]
  end
end
