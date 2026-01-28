# frozen_string_literal: true

FactoryBot.define do
  factory :estado do
    sequence(:nome) { |n| "Estado #{n}" }
    sequence(:sigla) { |n| "E#{n}" }
  end
end
