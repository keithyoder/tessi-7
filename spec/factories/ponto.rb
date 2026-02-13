# frozen_string_literal: true

FactoryBot.define do
  factory :ponto do
    # Sequências para valores únicos
    sequence(:nome) { |n| "Ponto #{n}" }
    sequence(:ip) { |n| "10.0.#{(n / 254) + 1}.#{(n % 254) + 1}" }
    sequence(:ipv6) { |n| format('2001:db8::%x', n) }

    # Associação obrigatória
    servidor

    # Atributos padrão
    sistema { :Mikrotik }
    tecnologia { :Radio }
    usuario { 'admin' }
    senha { 'senha123' }
    equipamento { 'locoM5' }

    # Trait para pontos de rádio
    trait :radio do
      tecnologia { :Radio }
      sistema { :Ubnt }
      equipamento { 'NanoStation loco M5' }
      sequence(:nome) { |n| "Torre Radio #{n}" }
    end

    # Trait para pontos de fibra
    trait :fibra do
      tecnologia { :Fibra }
      sistema { 'OLT Fiberhome' }
      equipamento { 'AN5516-06' }
      sequence(:nome) { |n| "OLT Fibra #{n}" }
    end
  end
end
