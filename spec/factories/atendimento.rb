# frozen_string_literal: true

FactoryBot.define do
  factory :atendimento do
    pessoa
    classificacao
    responsavel { association :user }

    fechamento { nil }

    trait :fechado do
      fechamento { 1.day.ago }
    end
  end
end
