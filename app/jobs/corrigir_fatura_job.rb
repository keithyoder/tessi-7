# frozen_string_literal: true

class CorrigirFaturaJob < ApplicationJob
  queue_as :default

  def perform(contrato_id:)
    @contrato_id = contrato_id
    criar_nova_fatura
    fatura_em_aberto.update(cancelamento: Date.today)
    fatura_paga.update(
      contrato_id: fatura_em_aberto.contrato_id,
      parcela: fatura_em_aberto.parcela,
      vencimento: fatura_em_aberto.vencimento,
      periodo_inicio: fatura_em_aberto.periodo_inicio,
      periodo_fim: fatura_em_aberto.periodo_fim
    )
  end

  private

  def antigo
    f1 = Fatura.find(839774)
    f2 = Fatura.find(839776)
    f2.contrato.faturas.create(pagamento_perfil_id: f2.pagamento_perfil_id, parcela: f2.parcela, vencimento: f2.vencimento, periodo_inicio: f2.periodo_inicio, periodo_fim: f2.periodo_fim, valor: f2.valor, nossonumero: '300002')
    f1.update(cancelamento: Date.today)
    f2.update(contrato_id: f1.contrato_id, parcela: f1.parcela, vencimento: f1.vencimento, periodo_inicio: f1.periodo_inicio, periodo_fim: f1.periodo_fim)
  end

  def contrato
    @contrato ||= Contrato.find(@contrato_id)
  end

  def fatura_paga
    @fatura_paga ||= @contrato.faturas.pagas.last
  end

  def fatura_em_aberto
    @fatura_em_aberto ||= @contrato.faturas.em_aberto.first
  end

  def criar_nova_fatura
    contrato.create(
      pagamento_perfil_id: fatura_paga.pagamento_perfil_id,
      parcela: fatura_paga..parcela,
      vencimento: fatura_paga..vencimento,
      periodo_inicio: fatura_paga..periodo_inicio,
      periodo_fim: fatura_paga..periodo_fim,
      valor: fatura_paga.valor,
      nossonumero: '300002'
    )
  end
end
