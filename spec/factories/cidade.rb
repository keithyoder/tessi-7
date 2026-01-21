# frozen_string_literal: true

FactoryBot.define do
  factory :cidade do
    nome { 'São Paulo' }
    ibge { 3_550_308 }
    estado
  end
end
