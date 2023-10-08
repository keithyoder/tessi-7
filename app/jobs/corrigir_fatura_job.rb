# frozen_string_literal: true

class GerarNotasJob < ApplicationJob
  queue_as :default

  def perform
    f1 = Fatura.find(857559)
    f2 = Fatura.find(857560)
    f2.contrato.faturas.create(pagamento_perfil_id: f2.pagamento_perfil_id, parcela: f2.parcela, vencimento: f2.vencimento, periodo_inicio: f2.periodo_inicio, periodo_fim: f2.periodo_fim, valor: f2.valor, nossonumero: '300002')
    f1.update(cancelamento: Date.today)
    f2.update(contrato_id: f1.contrato_id, parcela: f1.parcela, vencimento: f1.vencimento, periodo_inicio: f1.periodo_inicio, periodo_fim: f1.periodo_fim)
  end
end