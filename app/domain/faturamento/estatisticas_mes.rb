# frozen_string_literal: true

# app/domain/faturamento/estatisticas_mes.rb

module Faturamento
  # Calcula estatísticas mensais com totais acumulados (running totals)
  # e comparação com médias históricas por dia do mês.
  #
  # IMPORTANTE: Usa duas datas de referência:
  # - dia_atual_display: hoje (para mostrar dados diários incluindo hoje)
  # - dia_atual_comparacao: ontem (para comparar totais mensais com histórico)
  class EstatisticasMes
    attr_reader :ano, :mes, :inicio_mes, :fim_mes, :dia_atual_display, :dia_atual_comparacao

    def initialize(ano:, mes:)
      @ano = ano
      @mes = mes
      @inicio_mes = Date.new(ano, mes, 1)
      @fim_mes = @inicio_mes.end_of_month

      # Para mostrar dados diários (inclui hoje)
      @dia_atual_display = [Periods.data_hoje, @fim_mes].min

      # Para comparações mensais (só dias completos - até ontem)
      @dia_atual_comparacao = [Periods.data_limite, @fim_mes].min
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

    def calcular_dados_por_dia # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # Se o mês inteiro está no futuro, retorna vazio
      return [] if inicio_mes > Periods.data_hoje

      # Usa query compartilhada - carrega através de HOJE
      faturamento_por_dia = Queries.faturamento_por_dia(inicio_mes, dia_atual_display)

      dias_array = []
      acumulado_real = 0
      acumulado_esperado = 0

      (1..dia_atual_display.day).each do |dia|
        data = Date.new(ano, mes, dia)

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

      # Para totais mensais, usa apenas dias completos (até ontem)
      dias_completos = dados_por_dia.select { |d| d[:data] <= dia_atual_comparacao }

      return Calculations.resumo_vazio(dias_decorridos: dados_por_dia.count) if dias_completos.empty?

      ultimo_dia_completo = dias_completos.last
      total_faturas = dias_completos.sum { |d| d[:faturas_count] }

      # Usa builder compartilhado - comparação baseada em dias completos
      Calculations.build_resumo(
        total_recebido: ultimo_dia_completo[:acumulado_real],
        total_esperado: ultimo_dia_completo[:acumulado_esperado],
        total_faturas: total_faturas,
        dias_decorridos: dados_por_dia.count, # Mostra todos os dias incluindo hoje
        ticket_medio: Calculations.calcular_ticket_medio(
          ultimo_dia_completo[:acumulado_real],
          total_faturas
        )
      )
    end

    def calcular_projecao
      return 0 if dados_por_dia.empty?

      # Projeção baseada em dias completos (até ontem)
      dias_completos = dados_por_dia.select { |d| d[:data] <= dia_atual_comparacao }
      return 0 if dias_completos.empty?

      ultimo_dia_completo = dias_completos.last
      projecao = ultimo_dia_completo[:acumulado_real]

      # Adiciona médias históricas para os dias restantes
      ((ultimo_dia_completo[:dia] + 1)..31).each do |dia|
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
