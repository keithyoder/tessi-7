# frozen_string_literal: true

# spec/factories/logradouros.rb
FactoryBot.define do
  factory :logradouro do
    nome { 'Av. Paulista' }
    cep { '01310100' }
    bairro
  end
end
