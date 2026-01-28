# frozen_string_literal: true

FactoryBot.define do
  factory :fatura do
    contrato
    pagamento_perfil { contrato.pagamento_perfil }

    periodo_inicio { Time.zone.today.beginning_of_month }
    periodo_fim    { Time.zone.today.end_of_month }
    valor          { 100.0 }
    vencimento     { periodo_fim }
    nossonumero    { nil }
    cancelamento   { nil }
    registro_id    { nil }
    baixa_id       { nil }
    retorno_id     { nil }

    after(:build) do |fatura|
      # define parcela como max(parcela) + 1 para o contrato
      max_parcela = fatura.contrato.faturas.maximum(:parcela).to_i
      fatura.parcela = max_parcela + 1

      if fatura.pagamento_perfil && fatura.nossonumero.blank?
        proximo = fatura.pagamento_perfil.proximo_nosso_numero + 1
        fatura.nossonumero = proximo.to_s.rjust(7, '0') # 7 dígitos
      end
    end
  end
end
