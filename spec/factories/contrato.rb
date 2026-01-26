# frozen_string_literal: true

FactoryBot.define do
  factory :contrato do
    # Associations
    pessoa { association :pessoa, :fisica }
    plano  { association :plano }
    primeiro_vencimento { Time.zone.today + 1.month }
    dia_vencimento { Time.zone.today.day }
    pagamento_perfil { association :pagamento_perfil }

    # Attributes
    adesao { Time.zone.today }
  end
end
