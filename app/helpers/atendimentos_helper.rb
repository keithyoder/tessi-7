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
end
