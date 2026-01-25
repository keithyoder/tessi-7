# frozen_string_literal: true

FactoryBot.define do
  factory :pessoa do
    nome { 'Pessoa Default' }
    telefone1 { '11987654321' }
    logradouro

    trait :fisica do
      tipo { 'Pessoa Física' }
      cpf { '12345678900' }
      email { 'fisica@example.com' }
    end

    trait :juridica do
      tipo { 'Pessoa Jurídica' }
      cnpj { '12345678000199' }
      email { 'juridica@example.com' }
    end
  end
end
