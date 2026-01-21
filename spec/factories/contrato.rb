FactoryBot.define do
  factory :contrato do
    # Associations
    pessoa { association :pessoa_fisica }
    plano  { association :plano }

    # Attributes
    adesao { Date.today }
  end
end
