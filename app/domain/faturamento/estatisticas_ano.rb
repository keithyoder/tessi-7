# frozen_string_literal: true

# app/domain/faturamento/estatisticas_ano.rb

module Faturamento
  # Calcula estatísticas para todos os meses de um ano
  #
  class EstatisticasAno
    def initialize(ano:)
      @ano = ano
    end

    def call
      carregar_dados_batch
      meses_data = calcular_dados_por_mes

      {
        meses: meses_data,
        resumo: calcular_resumo(meses_data),
        ano_anterior: calcular_comparacao_ano_anterior(meses_data)
      }
    end

    private

    attr_reader :ano

    # ========================================================================
    # Carregamento de dados usando queries compartilhadas
    # ========================================================================

    def carregar_dados_batch
      # Usa query compartilhada para ano atual
      # IMPORTANTE: ano_range usa data_limite (ontem), então apenas dias completos
      range = Periods.ano_range(ano)
      @dados_ano_atual = Queries.faturamento_por_mes(range.first, range.last)

      # Usa query compartilhada para histórico
      anos_historicos = [ano - 1, ano - 2, ano - 3].select { |a| a >= 2020 }
      @dados_historicos = Queries.faturamento_historico_por_ano_mes(anos_historicos)

      # Carrega ano anterior se necessário
      return unless ano > 2020

      range_anterior = Periods.ano_range(ano - 1)
      @dados_ano_anterior = Queries.faturamento_por_mes(range_anterior.first, range_anterior.last)
    end

    # ========================================================================
    # Processamento usando cálculos compartilhados
    # ========================================================================

    def calcular_dados_por_mes
      meses = []

      (1..12).each do |mes|
        data_mes = Date.new(ano, mes, 1)
        break if data_mes > Date.current.beginning_of_month

        # Dados carregados através de data_limite (ontem)
        # Para o mês atual, mostra total apenas de dias completos
        mes_data = @dados_ano_atual[mes]
        quantidade = mes_data&.quantidade || 0
        total = mes_data&.total.to_f

        eh_mes_atual = Periods.mes_atual?(ano, mes)
        media_esperada = media_historica_mes(mes, parcial: eh_mes_atual)

        # Usa cálculo compartilhado
        comparacao = Calculations.calcular_comparacao(total, media_esperada)
        ticket_medio = Calculations.calcular_ticket_medio(total, quantidade)

        meses << {
          mes: mes,
          nome_mes: Date::MONTHNAMES[mes],
          total_recebido: total,
          total_faturas: quantidade,
          total_esperado: media_esperada,
          diferenca: comparacao[:diferenca],
          percentual_diferenca: comparacao[:percentual],
          ticket_medio: ticket_medio
        }
      end

      meses
    end

    def calcular_resumo(meses_data)
      return Calculations.resumo_vazio(meses_processados: 0, media_mensal: 0.0) if meses_data.empty?

      total_recebido = meses_data.sum { |m| m[:total_recebido] }
      total_esperado = meses_data.sum { |m| m[:total_esperado] }
      total_faturas = meses_data.sum { |m| m[:total_faturas] }
      meses_count = meses_data.length

      # Calcula média mensal ponderada (projeta mês parcial)
      media_mensal_ponderada = calcular_media_mensal_ponderada(meses_data)

      # Usa builder compartilhado
      Calculations.build_resumo(
        total_recebido: total_recebido,
        total_esperado: total_esperado,
        total_faturas: total_faturas,
        meses_processados: meses_count,
        media_mensal: media_mensal_ponderada
      )
    end

    def calcular_comparacao_ano_anterior(meses_data)
      return nil if ano == 2020 || @dados_ano_anterior.nil?

      total_ano_anterior = 0.0

      meses_data.each do |mes_data|
        mes = mes_data[:mes]
        eh_mes_atual = Periods.mes_atual?(ano, mes)

        if eh_mes_atual
          total_ano_anterior += calcular_total_parcial_ano_anterior(mes)
        else
          mes_anterior_data = @dados_ano_anterior[mes]
          total_ano_anterior += mes_anterior_data&.total.to_f
        end
      end

      return unless total_ano_anterior.positive?

      total_atual = meses_data.sum { |m| m[:total_recebido] }

      # Usa cálculo compartilhado
      comparacao = Calculations.calcular_comparacao(total_atual, total_ano_anterior)

      {
        ano: ano - 1,
        total: total_ano_anterior,
        diferenca: comparacao[:diferenca],
        percentual: comparacao[:percentual]
      }
    end

    # ========================================================================
    # Helpers para mês parcial
    # ========================================================================

    def media_historica_mes(mes, parcial: false)
      anos_historicos = [ano - 1, ano - 2, ano - 3].select { |a| a >= 2020 }
      return 0.0 if anos_historicos.empty?

      totais = if parcial
                 anos_historicos.map { |ano_hist| calcular_total_parcial_mes(ano_hist, mes) }
               else
                 anos_historicos.map { |ano_hist| @dados_historicos.dig(ano_hist, mes) || 0.0 }
               end

      totais_validos = totais.select(&:positive?)
      return 0.0 if totais_validos.empty?

      totais_validos.sum / totais_validos.length
    end

    def calcular_total_parcial_mes(ano_alvo, mes)
      # Usa o último dia completo (ontem) para comparações justas
      dia_limite = Periods.data_limite.day
      range = Periods.periodo_parcial_historico(ano_alvo, mes, dia_limite)

      # Usa query compartilhada
      dados = Queries.faturamento_total(range.first, range.last)
      dados[:total]
    end

    def calcular_total_parcial_ano_anterior(mes)
      calcular_total_parcial_mes(ano - 1, mes)
    end

    # ========================================================================
    # Média mensal ponderada
    # ========================================================================

    # Calcula média mensal incluindo projeção do mês parcial
    #
    # Para meses completos: usa valor real
    # Para mês atual parcial: projeta para mês completo baseado em dias
    #
    # Exemplo: Fevereiro com 5 dias completos de 28 total
    #   Real: R$ 55,000 (5 dias)
    #   Projeção: R$ 55,000 * (28/5) = R$ 308,000 (mês completo)
    #
    def calcular_media_mensal_ponderada(meses_data)
      return 0.0 if meses_data.empty?

      totais_projetados = meses_data.map do |mes_data|
        if Periods.mes_atual?(ano, mes_data[:mes])
          # Mês atual parcial - projeta para mês completo
          projetar_mes_completo(mes_data)
        else
          # Mês completo - usa valor real
          mes_data[:total_recebido]
        end
      end

      totais_projetados.sum / totais_projetados.length
    end

    # Projeta um mês parcial para mês completo
    #
    # @param mes_data [Hash] dados do mês parcial
    # @return [Float] valor projetado para mês completo
    def projetar_mes_completo(mes_data)
      mes = mes_data[:mes]
      total_parcial = mes_data[:total_recebido]

      # Dias completos até ontem
      dias_completos = Periods.data_limite.day

      # Total de dias no mês
      dias_no_mes = Date.new(ano, mes, 1).end_of_month.day

      # Se já está completo, retorna o valor real
      return total_parcial if dias_completos >= dias_no_mes

      # Projeta proporcionalmente: total_parcial * (dias_no_mes / dias_completos)
      (total_parcial * dias_no_mes / dias_completos.to_f).round(2)
    end
  end
end
