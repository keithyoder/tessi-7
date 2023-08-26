# frozen_string_literal: true

class FibraRede < ApplicationRecord
  belongs_to :ponto
  has_many :fibra_caixas
  has_many :conexoes, through: :fibra_caixas
  enum fibra_cor: %i[verde amarela branca azul vermelha
                     violeta marrom rosa preta cinza laranja aqua]
end
