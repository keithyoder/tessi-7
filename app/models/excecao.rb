# frozen_string_literal: true

# == Schema Information
#
# Table name: excecoes
#
#  id          :bigint           not null, primary key
#  tipo        :integer
#  usuario     :string
#  valido_ate  :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  contrato_id :bigint
#
# Indexes
#
#  index_excecoes_on_contrato_id  (contrato_id)
#
# Foreign Keys
#
#  fk_rails_...  (contrato_id => contratos.id)
#
class Excecao < ApplicationRecord
  belongs_to :contrato
  enum :tipo, { Bloqueio: 1, Desbloqueio: 2 }
  scope :validas_para_desbloqueio, lambda {
    where(tipo: :Desbloqueio)
    where("? BETWEEN DATE_TRUNC('day', created_at) and valido_ate", Date.today)
  }
  scope :validas_para_bloqueio, lambda {
    where(tipo: :Bloqueio)
    where("? BETWEEN DATE_TRUNC('day', created_at) and valido_ate", Date.today)
  }
end
