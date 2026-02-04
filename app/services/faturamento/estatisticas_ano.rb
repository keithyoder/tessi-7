# frozen_string_literal: true

module Faturamento
  # Calcula estatísticas para todos os meses de um ano
  #
  # OTIMIZAÇÃO: Carrega dados em batch para reduzir queries
  # - Maioria dos dados: 3 queries GROUP BY
  # - Mês atual parcial: queries adicionais apenas quando necessário
  # - Total: ~7 queries vs 72+ original
  #
  # FEATURE: Suporta comparações de mês parcial
  # - Compara Janeiro 1-4 de 2025 com Janeiro 1-4 de anos anteriores
  # - Garante comparações justas (mesmo período)
  #
  # Retorna estrutura com:
  # - meses: array com dados mensais
  # - resumo: totalizadores do ano
  # - ano_anterior: comparação com ano anterior
  #
  class EstatisticasAno
    def initialize(ano:)
      @ano = ano
    end

    def call
      # Carrega dados em batch (3 queries principais)
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
    # OTIMIZAÇÃO: Carrega TODOS os dados necessários em 3 queries principais
    # ========================================================================

    def carregar_dados_batch
      @dados_ano_atual = carregar_ano_completo(ano)
      @dados_historicos = carregar_dados_historicos
      @dados_ano_anterior = carregar_ano_completo(ano - 1) if ano > 2020
    end

    # Carrega todos os 12 meses de um ano em 1 query
    def carregar_ano_completo(ano_alvo)
      data_inicio = Date.new(ano_alvo, 1, 1)
      data_fim = Date.new(ano_alvo, 12, 31)

      # Não buscar além de hoje
      data_fim = [data_fim, Date.current].min

      resultado = Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(Arel.sql('EXTRACT(month FROM liquidacao)'))
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(month FROM liquidacao)::int as mes'),
          Arel.sql('COUNT(*) as quantidade'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )

      # Converte para hash indexado por mês
      resultado.index_by(&:mes)
    end

    # Carrega 3 anos históricos em 1 query
    def carregar_dados_historicos
      anos_historicos = [ano - 1, ano - 2, ano - 3].select { |a| a >= 2020 }
      return {} if anos_historicos.empty?

      data_inicio = Date.new(anos_historicos.min, 1, 1)
      data_fim = Date.new(anos_historicos.max, 12, 31)

      resultado = Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(
          Arel.sql('EXTRACT(year FROM liquidacao)'),
          Arel.sql('EXTRACT(month FROM liquidacao)')
        )
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(year FROM liquidacao)::int as ano'),
          Arel.sql('EXTRACT(month FROM liquidacao)::int as mes'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )

      # Converte para hash aninhado: { ano => { mes => total } }
      dados = {}
      resultado.each do |r|
        dados[r.ano] ||= {}
        dados[r.ano][r.mes] = r.total.to_f
      end
      dados
    end

    # ========================================================================
    # Processamento usando dados pré-carregados
    # ========================================================================

    def calcular_dados_por_mes
      meses = []

      (1..12).each do |mes|
        # Pular meses futuros
        data_mes = Date.new(ano, mes, 1)
        break if data_mes > Date.current.beginning_of_month

        # Usa dados pré-carregados
        mes_data = @dados_ano_atual[mes]
        quantidade = mes_data&.quantidade || 0
        total = mes_data&.total.to_f

        # Detecta se é mês atual para comparação parcial
        eh_mes_atual = ano == Date.current.year && mes == Date.current.month
        media_esperada = media_historica_mes(mes, parcial: eh_mes_atual)

        diferenca = total - media_esperada
        percentual = media_esperada.zero? ? 0.0 : (diferenca / media_esperada * 100)

        meses << {
          mes: mes,
          nome_mes: Date::MONTHNAMES[mes],
          total_recebido: total,
          total_faturas: quantidade,
          total_esperado: media_esperada,
          diferenca: diferenca,
          percentual_diferenca: percentual
        }
      end

      meses
    end

    def calcular_resumo(meses_data)
      return resumo_vazio if meses_data.empty?

      total_recebido = meses_data.sum { |m| m[:total_recebido] }
      total_esperado = meses_data.sum { |m| m[:total_esperado] }
      diferenca = total_recebido - total_esperado
      percentual = total_esperado.zero? ? 0.0 : (diferenca / total_esperado * 100)
      total_faturas = meses_data.sum { |m| m[:total_faturas] }

      {
        total_recebido: total_recebido,
        total_esperado: total_esperado,
        diferenca: diferenca,
        percentual_diferenca: percentual,
        total_faturas: total_faturas,
        meses_processados: meses_data.length,
        media_mensal: meses_data.length.positive? ? (total_recebido / meses_data.length) : 0.0
      }
    end

    def calcular_comparacao_ano_anterior(meses_data)
      return nil if ano == 2020 || @dados_ano_anterior.nil?

      total_ano_anterior = 0.0

      meses_data.each do |mes_data|
        mes = mes_data[:mes]

        # Detecta se é o mês atual para comparação parcial
        eh_mes_atual = ano == Date.current.year && mes == Date.current.month

        if eh_mes_atual
          # Para mês atual, fazer comparação parcial (mesmo período do ano anterior)
          total_ano_anterior += calcular_total_parcial_ano_anterior(mes)
        else
          # Para meses completos, usar dados pré-carregados
          mes_anterior_data = @dados_ano_anterior[mes]
          total_ano_anterior += mes_anterior_data&.total.to_f
        end
      end

      return unless total_ano_anterior.positive?

      total_atual = meses_data.sum { |m| m[:total_recebido] }
      diferenca = total_atual - total_ano_anterior
      percentual = (diferenca / total_ano_anterior * 100)

      {
        ano: ano - 1,
        total: total_ano_anterior,
        diferenca: diferenca,
        percentual: percentual
      }
    end

    # ========================================================================
    # Helpers para mês parcial (queries adicionais apenas quando necessário)
    # ========================================================================

    def media_historica_mes(mes, parcial: false)
      anos_historicos = [ano - 1, ano - 2, ano - 3].select { |a| a >= 2020 }
      return 0.0 if anos_historicos.empty?

      totais = if parcial
                 # Para mês atual, calcular média parcial (mesmo período histórico)
                 # Faz 3 queries adicionais (1 por ano histórico)
                 anos_historicos.map do |ano_hist|
                   calcular_total_parcial_mes(ano_hist, mes)
                 end
               else
                 # Para meses completos, usar dados pré-carregados (sem queries!)
                 anos_historicos.map do |ano_hist|
                   @dados_historicos.dig(ano_hist, mes) || 0.0
                 end
               end

      totais_validos = totais.select(&:positive?)
      return 0.0 if totais_validos.empty?

      totais_validos.sum / totais_validos.length
    end

    def calcular_total_parcial_mes(ano_alvo, mes)
      data_inicio = Date.new(ano_alvo, mes, 1)
      data_fim = data_inicio.end_of_month

      # Usar apenas até o dia atual do mês
      dia_atual = Date.current.day
      dia_limite = [dia_atual, data_fim.day].min
      data_fim = Date.new(ano_alvo, mes, dia_limite)

      Fatura
        .where(liquidacao: data_inicio..data_fim)
        .sum(:valor_liquidacao)
        .to_f
    end

    def calcular_total_parcial_ano_anterior(mes)
      ano_anterior = ano - 1
      data_inicio = Date.new(ano_anterior, mes, 1)
      data_fim = data_inicio.end_of_month

      # Se for o mês atual, usar apenas até o dia atual
      dia_atual = Date.current.day
      dia_limite = [dia_atual, data_fim.day].min
      data_fim = Date.new(ano_anterior, mes, dia_limite)

      Fatura
        .where(liquidacao: data_inicio..data_fim)
        .sum(:valor_liquidacao)
        .to_f
    end

    def resumo_vazio
      {
        total_recebido: 0.0,
        total_esperado: 0.0,
        diferenca: 0.0,
        percentual_diferenca: 0.0,
        total_faturas: 0,
        meses_processados: 0,
        media_mensal: 0.0
      }
    end
  end
end
