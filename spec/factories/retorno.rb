# frozen_string_literal: true

FactoryBot.define do
  factory :retorno do
    pagamento_perfil { association :pagamento_perfil }
  end
end
