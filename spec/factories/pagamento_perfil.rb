# spec/factories/pagamento_perfis.rb
FactoryBot.define do
  factory :pagamento_perfil do
    nome      { 'Perfil Default' }
    banco     { 1 }
    agencia   { 1234 }
    conta     { 56_789 }
    cedente   { 123_456 }
    carteira  { '18' }
    tipo      { 'Boleto' }
    ativo     { true }
    sequencia { 1 }
  end
end
