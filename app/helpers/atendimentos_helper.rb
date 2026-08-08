# frozen_string_literal: true

module AtendimentosHelper
  def cor_dias_aberto(atendimento)
    return 'text-muted' if atendimento.fechamento.present?

    dias = atendimento.dias_aberto
    if dias <= 10
      'text-success'
    elsif dias <= 30
      'text-warning'
    else
      'text-danger'
    end
  end

  def label_fatura(fatura)
    "##{fatura.id} — #{l(fatura.vencimento)} — #{number_to_currency(fatura.valor)}"
  end

  def label_contrato(contrato)
    "##{contrato.id} — Adesão #{l(contrato.adesao)}"
  end

  def label_conexao_form(conexao)
    "#{conexao.ip} — #{conexao.usuario} — #{conexao.ponto.nome}"
  end
end
