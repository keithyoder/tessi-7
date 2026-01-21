# frozen_string_literal: true

FactoryBot.define do
  factory :pessoa do
    nome { 'Pessoa Default' }
    telefone1 { '11987654321' }
    logradouro { create(:logradouro) }

    # Subfactory for pessoa física (optional, mostly redundant here)
    factory :pessoa_fisica do
      tipo { 'Pessoa Física' }
      cpf { '12345678900' }
      email { 'fisica@example.com' }
    end

    # Subfactory for pessoa jurídica
    factory :pessoa_juridica do
      tipo { 'Pessoa Jurídica' }
      cnpj { '12345678000199' }
      razao_social { 'Empresa Exemplo LTDA' }
      email { 'juridica@example.com' }
    end
  end
end
