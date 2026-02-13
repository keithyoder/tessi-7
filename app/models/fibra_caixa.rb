# frozen_string_literal: true

# == Schema Information
#
# Table name: fibra_caixas
#
#  id            :bigint           not null, primary key
#  capacidade    :integer
#  fibra_cor     :integer
#  latitude      :decimal(10, 6)
#  longitude     :decimal(10, 6)
#  nome          :string
#  poste         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  fibra_rede_id :bigint
#  logradouro_id :bigint
#
# Indexes
#
#  index_fibra_caixas_on_fibra_rede_id  (fibra_rede_id)
#  index_fibra_caixas_on_logradouro_id  (logradouro_id)
#
# Foreign Keys
#
#  fk_rails_...  (fibra_rede_id => fibra_redes.id)
#
class FibraCaixa < ApplicationRecord
  belongs_to :fibra_rede
  belongs_to :logradouro, optional: true
  has_one :ponto, through: :fibra_rede
  has_many :conexoes, foreign_key: :caixa_id
  enum :fibra_cor, { verde: 0, amarela: 1, branca: 2, azul: 3, vermelha: 4, violeta: 5, marrom: 6,
                     rosa: 7, preta: 8, cinza: 9, laranja: 10, aqua: 11 }
end
