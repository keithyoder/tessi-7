# frozen_string_literal: true

module Faturamento
  # Calcula a média histórica de faturamento para cada dia do mês (1-31)
  # baseado nos últimos N meses completos.
  #
  # IMPORTANTE: A média é calculada dividindo pelo TOTAL de meses no período,
  # não apenas pelos meses que têm aquele dia.
  #
  # Para cada dia do mês:
  # - Soma todas as faturas liquidadas naquele dia através dos meses
  # - Divide pelo número TOTAL de meses no período
  #
  # Exemplo: Dia 31 soma R$ 70.000 em 12 meses históricos
  #   - Dia 31 existe em apenas 7 meses (Jan, Mar, Mai, Jul, Ago, Out, Dez)
  #   - Média = R$ 70.000 / 12 = R$ 5.833 (não R$ 70.000 / 7)
  #   - Os outros 5 meses contribuem R$ 0, então devem ser incluídos no divisor
  #
  # Isso permite comparação justa entre dias e projeções precisas.
  class MediasPorDiaDoMes
    def initialize(meses_atras: 13, excluir_mes_atual: true)
      @meses_atras = meses_atras
      @excluir_mes_atual = excluir_mes_atual
    end

    def call
      return {} if periodo_invalido?

      calcular_medias
    end

    private

    attr_reader :meses_atras, :excluir_mes_atual

    def calcular_medias
      medias = {}
      total_meses = calcular_total_meses

      historico_por_dia.each do |registro|
        dia = registro.dia_do_mes
        total = registro.total_dia.to_f

        # Divide pelo TOTAL de meses, não apenas meses com esse dia
        medias[dia] = total_meses.positive? ? (total / total_meses) : 0
      end

      medias
    end

    def historico_por_dia
      # Use .reorder(nil) to remove default ordering for GROUP BY queries
      Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(Arel.sql('EXTRACT(day FROM liquidacao)'))
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(day FROM liquidacao)::int as dia_do_mes'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total_dia')
        )
    end

    def calcular_total_meses
      # Número de meses completos no período histórico
      meses_completos = 0
      current = data_inicio.beginning_of_month

      while current <= data_fim.beginning_of_month
        meses_completos += 1
        current += 1.month
      end

      meses_completos
    end

    def data_inicio
      @data_inicio ||= meses_atras.months.ago.beginning_of_month
    end

    def data_fim
      @data_fim ||= if excluir_mes_atual
                      1.month.ago.end_of_month
                    else
                      Date.current
                    end
    end

    def periodo_invalido?
      data_inicio >= data_fim
    end
  end
end
