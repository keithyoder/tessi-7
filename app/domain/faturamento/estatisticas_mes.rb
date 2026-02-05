# frozen_string_literal: true

# app/domain/faturamento/estatisticas_mes.rb

module Faturamento
  # Calcula estatísticas mensais com totais acumulados (running totals)
  # e comparação com médias históricas por dia do mês.
  class EstatisticasMes
    attr_reader :ano, :mes, :inicio_mes, :fim_mes, :dia_atual

    def initialize(ano:, mes:)
      @ano = ano
      @mes = mes
      @inicio_mes = Date.new(ano, mes, 1)
      @fim_mes = @inicio_mes.end_of_month
      @dia_atual = Periods.ultimo_dia_disponivel(ano, mes)
    end

    def call
      {
        dias: calcular_dados_por_dia,
        resumo: calcular_resumo,
        projecao: calcular_projecao,
        medias_historicas: medias_historicas
      }
    end

    private

    def calcular_dados_por_dia
      # Usa query compartilhada
      faturamento_por_dia = Queries.faturamento_por_dia(inicio_mes, dia_atual)

      dias_array = []
      acumulado_real = 0
      acumulado_esperado = 0

      (1..fim_mes.day).each do |dia|
        data = Date.new(ano, mes, dia)
        break if data > Date.current

        # Usa dados pré-carregados
        dia_data = faturamento_por_dia[dia]
        quantidade = dia_data&.quantidade || 0
        valor_dia = dia_data&.total.to_f

        media_historica_dia = medias_historicas[dia] || 0

        # Totais acumulados
        acumulado_real += valor_dia
        acumulado_esperado += media_historica_dia

        # Usa cálculo compartilhado
        comparacao = Calculations.calcular_comparacao(acumulado_real, acumulado_esperado)

        dias_array << {
          dia: dia,
          data: data,
          faturas_count: quantidade,
          faturamento_dia: valor_dia,
          acumulado_real: acumulado_real,
          acumulado_esperado: acumulado_esperado,
          diferenca: comparacao[:diferenca],
          diferenca_percentual: comparacao[:percentual],
          performance: comparacao[:performance]
        }
      end

      dias_array
    end

    def calcular_resumo
      return Calculations.resumo_vazio(dias_decorridos: 0) if dados_por_dia.empty?

      ultimo_dia = dados_por_dia.last
      total_faturas = dados_por_dia.sum { |d| d[:faturas_count] }

      # Usa builder compartilhado
      Calculations.build_resumo(
        total_recebido: ultimo_dia[:acumulado_real],
        total_esperado: ultimo_dia[:acumulado_esperado],
        total_faturas: total_faturas,
        dias_decorridos: dados_por_dia.count,
        ticket_medio: Calculations.calcular_ticket_medio(ultimo_dia[:acumulado_real], total_faturas)
      )
    end

    def calcular_projecao
      return 0 if dados_por_dia.empty?

      ultimo_dia = dados_por_dia.last
      projecao = ultimo_dia[:acumulado_real]

      # Adiciona médias históricas para os dias restantes
      ((ultimo_dia[:dia] + 1)..31).each do |dia|
        projecao += medias_historicas[dia] || 0
      end

      projecao
    end

    def medias_historicas
      @medias_historicas ||= MediasPorDiaDoMes.new(
        meses_atras: 13,
        excluir_mes_atual: Periods.mes_atual?(ano, mes)
      ).call
    end

    def dados_por_dia
      @dados_por_dia ||= calcular_dados_por_dia
    end
  end
end
