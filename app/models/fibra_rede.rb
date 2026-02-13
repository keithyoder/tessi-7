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
  has_many :fibra_caixas
  has_many :conexoes, through: :fibra_caixas
  enum :fibra_cor, { verde: 0, amarela: 1, branca: 2, azul: 3, vermelha: 4, violeta: 5, marrom: 6,
                     rosa: 7, preta: 8, cinza: 9, laranja: 10, aqua: 11 }

  RANSACK_ATTRIBUTES = %w[nome].freeze
  RANSACK_ASSOCIATIONS = %w[].freeze
end
