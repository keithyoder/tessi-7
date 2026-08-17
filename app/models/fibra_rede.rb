# frozen_string_literal: true

# == Schema Information
#
# Table name: fibra_redes
#
#  id         :bigint           not null, primary key
#  fibra_cor  :integer
#  nome       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ponto_id   :bigint
#
# Indexes
#
#  index_fibra_redes_on_ponto_id  (ponto_id)
#
# Foreign Keys
#
#  fk_rails_...  (ponto_id => pontos.id)
#
class FibraRede < ApplicationRecord
  include Ransackable

  belongs_to :ponto
  has_many :caixas, class_name: 'FibraCaixa', dependent: :restrict_with_exception
  has_many :conexoes, through: :caixas
  has_many :os, as: :infraestrutura, dependent: :nullify
  enum :fibra_cor, Fibra::Cores::CORES

  RANSACK_ATTRIBUTES = %w[nome].freeze
  RANSACK_ASSOCIATIONS = %w[].freeze

  def latitude
    caixas.average(:latitude)
  end

  def longitude
    caixas.average(:longitude)
  end
end
