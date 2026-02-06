# frozen_string_literal: true

FactoryBot.define do
  factory :pessoa do
    nome { 'Pessoa Default' }
    telefone1 { '11987654321' }
    logradouro

    trait :fisica do
      tipo { 'Pessoa Física' }
      sequence(:cpf) { |n| (100_000_000_00 + n).to_s }
      email { 'fisica@example.com' }
    end

    trait :juridica do
      tipo { 'Pessoa Jurídica' }
      sequence(:cnpj) { |n| (100_000_000_000_000 + n).to_s }
      email { 'juridica@example.com' }
    end
  end
end
