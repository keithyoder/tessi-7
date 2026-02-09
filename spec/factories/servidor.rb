# frozen_string_literal: true

FactoryBot.define do
  factory :servidor do
    # Sequências para valores únicos
    sequence(:nome) { |n| "Servidor #{n}" }
    sequence(:ip) { |n| "10.10.#{(n / 254) + 1}.#{(n % 254) + 1}" }

    # Atributos padrão
    # sistema { 'MikroTik RouterOS' }
    usuario { 'admin' }
    senha { 'senha_segura_123' }
    ssh_porta { 8728 } # Porta padrão API MikroTik

    # Coordenadas geográficas opcionais (exemplo: Pesqueira, PE)
    # latitude { -8.3559 }
    # longitude { -36.6956 }
  end
end
