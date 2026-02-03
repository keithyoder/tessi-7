# frozen_string_literal: true

module Faturamento
  # Calcula estatísticas mensais com totais acumulados (running totals)
  # e comparação com médias históricas por dia do mês.
  #
  # Retorna:
  # - dias: Array com dados de cada dia incluindo acumulados
  # - resumo: Estatísticas gerais do mês
  # - projecao: Projeção para o mês completo
  class EstatisticasMes
    attr_reader :ano, :mes, :inicio_mes, :fim_mes, :dia_atual

    def initialize(ano:, mes:)
      @ano = ano
      @mes = mes
      @inicio_mes = Date.new(ano, mes, 1)
      @fim_mes = @inicio_mes.end_of_month
      @dia_atual = [@fim_mes, Date.current].min
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

    def carregar_faturamento_mes
      # UMA query que agrupa por dia e retorna count + sum
      resultado = Fatura
        .where(liquidacao: inicio_mes..dia_atual)
        .group(Arel.sql('EXTRACT(day FROM liquidacao)'))
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(day FROM liquidacao)::int as dia'),
          Arel.sql('COUNT(*) as quantidade'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )

      # Converte para hash indexado por dia para acesso O(1)
      resultado.index_by(&:dia)
    end

    def calcular_dados_por_dia
      # Carrega todos os dados do mês em UMA query
      faturamento_por_dia = carregar_faturamento_mes

      dias_array = []
      acumulado_real = 0
      acumulado_esperado = 0

      (1..fim_mes.day).each do |dia|
        data = Date.new(ano, mes, dia)
        break if data > Date.current # Não mostrar dias futuros

        # Usa dados pré-carregados (sem fazer query!)
        dia_data = faturamento_por_dia[dia]
        quantidade = dia_data&.quantidade || 0
        valor_dia = dia_data&.total&.to_f || 0.0

        media_historica_dia = medias_historicas[dia] || 0

        # Totais acumulados (running totals)
        acumulado_real += valor_dia
        acumulado_esperado += media_historica_dia

        # Diferença acumulada
        diferenca = acumulado_real - acumulado_esperado
        diferenca_percentual = if acumulado_esperado.positive?
                                 (diferenca / acumulado_esperado * 100)
                               else
                                 0
                               end

        dias_array << {
          dia: dia,
          data: data,
          faturas_count: quantidade,
          faturamento_dia: valor_dia,
          acumulado_real: acumulado_real,
          acumulado_esperado: acumulado_esperado,
          diferenca: diferenca,
          diferenca_percentual: diferenca_percentual.round(2),
          performance: diferenca >= 0 ? :acima : :abaixo
        }
      end

      dias_array
    end

    def calcular_resumo
      return resumo_vazio if dados_por_dia.empty?

      ultimo_dia = dados_por_dia.last

      {
        total_mes: ultimo_dia[:acumulado_real],
        total_esperado: ultimo_dia[:acumulado_esperado],
        diferenca_valor: ultimo_dia[:diferenca],
        diferenca_percentual: ultimo_dia[:diferenca_percentual],
        performance: ultimo_dia[:performance],
        dias_decorridos: dados_por_dia.count,
        total_faturas: dados_por_dia.sum { |d| d[:faturas_count] },
        ticket_medio: calcular_ticket_medio(ultimo_dia)
      }
    end

    def calcular_projecao
      return 0 if dados_por_dia.empty?

      ultimo_dia = dados_por_dia.last
      projecao = ultimo_dia[:acumulado_real]

      # Adiciona médias históricas para os dias restantes
      ((ultimo_dia[:dia] + 1)..fim_mes.day).each do |dia|
        projecao += medias_historicas[dia] || 0
      end

      projecao
    end

    def medias_historicas
      @medias_historicas ||= MediasPorDiaDoMes.new(
        meses_atras: 13,
        excluir_mes_atual: mes_atual?
      ).call
    end

    def dados_por_dia
      @dados_por_dia ||= calcular_dados_por_dia
    end

    # Método não é mais necessário mas mantido para compatibilidade
    # Agora usa carregar_faturamento_mes que é muito mais eficiente
    def consultar_faturamento_dia(data)
      scope = Fatura.where(liquidacao: data)

      {
        quantidade: scope.count,
        valor: scope.sum(:valor_liquidacao).to_f
      }
    end

    def calcular_ticket_medio(ultimo_dia)
      total_faturas = dados_por_dia.sum { |d| d[:faturas_count] }
      return 0 if total_faturas.zero?

      (ultimo_dia[:acumulado_real] / total_faturas).round(2)
    end

    def mes_atual?
      ano == Date.current.year && mes == Date.current.month
    end

    def resumo_vazio
      {
        total_mes: 0,
        total_esperado: 0,
        diferenca_valor: 0,
        diferenca_percentual: 0,
        performance: :neutro,
        dias_decorridos: 0,
        total_faturas: 0,
        ticket_medio: 0
      }
    end
  end
end
