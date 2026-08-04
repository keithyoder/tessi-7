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

  def self.ransackable_attributes(_auth_object = nil)
    %w[id nome tipo created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[atendimentos os]
  end
end
