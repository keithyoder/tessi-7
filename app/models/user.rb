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
    financeiro_n2: 4
  }
end
