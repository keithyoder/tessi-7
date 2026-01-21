# frozen_string_literal: true

FactoryBot.define do
  factory :contrato do
    # Associations
    pessoa { association :pessoa_fisica }
    plano  { association :plano }

    # Attributes
    adesao { Time.zone.today }
  end
end
