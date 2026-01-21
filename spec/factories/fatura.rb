# frozen_string_literal: true

FactoryBot.define do
  factory :fatura do
    contrato { association :contrato, pessoa: nil, plano: nil } # will use any_contrato
    periodo_inicio { Date.today.beginning_of_month }
    periodo_fim { Date.today.end_of_month }
    valor { 100.0 }
    vencimento { fim }
    nossonumero { nil }
    cancelamento { nil }
    registro_id { nil }
    baixa_id { nil }
    retorno_id { nil }
  end
end
