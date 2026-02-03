# frozen_string_literal: true

module Faturamento
  # Calcula estatísticas para todos os meses de um ano
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
      meses_data = calcular_dados_por_mes

      {
        meses: meses_data,
        resumo: calcular_resumo(meses_data),
        ano_anterior: calcular_comparacao_ano_anterior(meses_data)
      }
    end

    private

    attr_reader :ano

    def calcular_dados_por_mes
      meses = []

      (1..12).each do |mes|
        # Pular meses futuros
        data_mes = Date.new(ano, mes, 1)
        break if data_mes > Date.current.beginning_of_month

        mes_stats = estatisticas_mes(mes)
        media_esperada = media_historica_mes(mes)
        diferenca = mes_stats[:total] - media_esperada
        percentual = media_esperada.zero? ? 0.0 : (diferenca / media_esperada * 100)

        meses << {
          mes: mes,
          nome_mes: Date::MONTHNAMES[mes],
          total_recebido: mes_stats[:total],
          total_faturas: mes_stats[:quantidade],
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
      return nil if ano == 2020 # Sem dados anteriores

      ano_anterior = ano - 1
      total_ano_anterior = 0.0

      meses_data.each do |mes_data|
        mes = mes_data[:mes]
        data_inicio = Date.new(ano_anterior, mes, 1)
        data_fim = data_inicio.end_of_month

        total = Fatura
          .where(liquidacao: data_inicio..data_fim)
          .sum(:valor_liquidacao)
          .to_f

        total_ano_anterior += total
      end

      if total_ano_anterior.positive?
        total_atual = meses_data.sum { |m| m[:total_recebido] }
        diferenca = total_atual - total_ano_anterior
        percentual = (diferenca / total_ano_anterior * 100)

        {
          ano: ano_anterior,
          total: total_ano_anterior,
          diferenca: diferenca,
          percentual: percentual
        }
      else
        nil
      end
    end

    def estatisticas_mes(mes)
      data_inicio = Date.new(ano, mes, 1)
      data_fim = data_inicio.end_of_month

      # Não contar além de hoje
      data_fim = [data_fim, Date.current].min

      scope = Fatura.where(liquidacao: data_inicio..data_fim)

      {
        quantidade: scope.count,
        total: scope.sum(:valor_liquidacao).to_f
      }
    end

    def media_historica_mes(mes)
      # Média dos últimos 3 anos para este mês (excluindo ano atual)
      anos_historicos = [ano - 1, ano - 2, ano - 3].select { |a| a >= 2020 }

      return 0.0 if anos_historicos.empty?

      totais = anos_historicos.map do |ano_hist|
        data_inicio = Date.new(ano_hist, mes, 1)
        data_fim = data_inicio.end_of_month

        Fatura
          .where(liquidacao: data_inicio..data_fim)
          .sum(:valor_liquidacao)
          .to_f
      end

      totais_validos = totais.select(&:positive?)
      return 0.0 if totais_validos.empty?

      totais_validos.sum / totais_validos.length
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
