# frozen_string_literal: true

class FibraCaixa < ApplicationRecord
  belongs_to :fibra_rede
  belongs_to :logradouro, optional: true
  has_one :ponto, through: :fibra_rede
  has_many :conexoes, foreign_key: :caixa_id
  enum fibra_cor: %i[verde amarela branca azul vermelha
                     violeta marrom rosa preta cinza laranja aqua]
end
