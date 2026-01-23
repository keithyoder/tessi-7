# app/domain/faturas/calendario.rb
# frozen_string_literal: true

module Faturas
  # Responsável exclusivamente pelas regras de calendário de faturas.
  #
  # NÃO conhece modelos
  # NÃO acessa banco
  # NÃO calcula valores
  #
  # Fonte única de verdade para:
  # - vencimentos
  # - avanço de meses
  # - períodos de cobrança
  #
  module Calendario
    module_function

    # ------------------------------------------------------------------
    # API pública
    # ------------------------------------------------------------------

    # Calcula o próximo vencimento a partir de uma data base
    # respeitando dia de vencimento e regras anti-ciclo-curto.
    def proximo_vencimento(data_base, dia_vencimento)
      proximo = data_base + 1.month
      proximo = ajustar_dia(proximo, dia_vencimento)

      # proteção contra ciclos curtos (regra histórica)
      if (proximo - data_base).between?(2, 10)
        proximo += 1.month
        proximo = ajustar_dia(proximo, dia_vencimento)
      end

      proximo
    end

    # Avança N meses contratuais a partir de um vencimento
    #
    # Usado para meses_por_fatura > 1
    #
    def avancar_meses(vencimento_atual, dia_vencimento, meses:)
      raise ArgumentError, 'meses deve ser >= 1' if meses.to_i < 1

      meses.times.reduce(vencimento_atual) do |venc, _|
        proximo_vencimento(venc, dia_vencimento)
      end
    end

    # Retorna o período coberto por uma fatura
    #
    # REGRA FIXA:
    # - início = dia seguinte ao vencimento anterior
    # - fim    = vencimento atual
    #
    def periodo(vencimento_anterior, vencimento_atual)
      {
        inicio: vencimento_anterior + 1.day,
        fim: vencimento_atual
      }
    end

    # Primeiro período (quando não há faturas anteriores)
    #
    def primeiro_periodo(adesao, vencimento)
      {
        inicio: adesao,
        fim: vencimento
      }
    end

    # ------------------------------------------------------------------
    # Helpers privados (ainda puros)
    # ------------------------------------------------------------------

    def ajustar_dia(data, dia_vencimento)
      data.change(
        day: [dia_vencimento, data.end_of_month.day].min
      )
    end
    private_class_method :ajustar_dia
  end
end
