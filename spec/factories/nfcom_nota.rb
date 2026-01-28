# frozen_string_literal: true

FactoryBot.define do
  factory :nfcom_nota do
    fatura
    competencia { Faker::Date.backward(days: 30) }
    numero { NfcomNota.proximo_numero }
    serie { 1 }
    status { 'pending' }
    valor_total { Faker::Commerce.price(range: 100.0..1000.0, as_string: false) }
    chave_acesso { nil }
    protocolo { nil }
    xml_autorizado { nil }
    data_autorizacao { nil }
    mensagem_sefaz { nil }

    trait :authorized do
      status { 'authorized' }
      chave_acesso { Faker::Alphanumeric.alphanumeric(number: 44).upcase }
      protocolo { Faker::Number.number(digits: 15).to_s }
      xml_autorizado { '<xml>conteudo autorizado</xml>' }
      data_autorizacao { Time.current }
    end

    trait :rejected do
      status { 'rejected' }
      mensagem_sefaz { 'Rejeição exemplo' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end
  end
end
