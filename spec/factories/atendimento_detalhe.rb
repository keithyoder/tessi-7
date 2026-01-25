# frozen_string_literal: true

FactoryBot.define do
  factory :atendimento_detalhe do
    atendimento
    atendente factory: %i[user]

    tipo { :Presencial }
    descricao { 'Atendimento realizado' }

    trait :presencial do
      tipo { :Presencial }
      descricao { 'Atendimento presencial realizado' }
    end

    trait :telefonico do
      tipo { :Telefonico }
      descricao { 'Atendimento telefônico realizado' }
    end

    trait :online do
      tipo { :Online }
      descricao { 'Atendimento online realizado' }
    end

    trait :acesso_suspenso do
      tipo { :Presencial }
      descricao { 'Acesso Suspenso' }
    end

    trait :acesso_liberado do
      tipo { :Presencial }
      descricao { 'Acesso Liberado' }
    end
  end
end
