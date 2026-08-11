# frozen_string_literal: true

# -*- SkipSchemaAnnotations

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  attribute :role, :integer

  enum :role, {
    admin: 0,
    tecnico_n1: 1,
    tecnico_n2: 2,
    financeiro_n1: 3,
    financeiro_n2: 4,
    tecnico_campo: 5
  }

  CARGOS_ATENDENTE = %w[admin tecnico_n1 tecnico_n2 financeiro_n1 financeiro_n2].freeze

  scope :atendentes, -> { where(role: CARGOS_ATENDENTE) }
  scope :campo,      -> { where(role: :tecnico_campo) }

  def atendente?
    role.present? && CARGOS_ATENDENTE.include?(role)
  end
end
