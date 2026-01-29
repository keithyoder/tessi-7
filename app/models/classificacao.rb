# frozen_string_literal: true

# == Schema Information
#
# Table name: classificacoes
#
#  id         :bigint           not null, primary key
#  nome       :string
#  tipo       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Classificacao < ApplicationRecord
  has_many :os, dependent: :restrict_with_error
  has_many :atendimentos, dependent: :restrict_with_error

  enum :tipo, {
    Instalação: 1,
    Reparo: 2,
    Transferência: 3,
    Retirada: 4,
    Atendimento: 5
  }

  scope :atendimentos, -> { where(tipo: :Atendimento) }
  scope :os, -> { where.not(tipo: :Atendimento) }
end
