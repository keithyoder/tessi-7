# frozen_string_literal: true

class FibraRede < ApplicationRecord
  include Ransackable

  belongs_to :ponto
  has_many :fibra_caixas
  has_many :conexoes, through: :fibra_caixas
  enum fibra_cor: %i[verde amarela branca azul vermelha
                     violeta marrom rosa preta cinza laranja aqua]

  RANSACK_ATTRIBUTES = %w[nome].freeze
  RANSACK_ASSOCIATIONS = %w[].freeze                 
end
