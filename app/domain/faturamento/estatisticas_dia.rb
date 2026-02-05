# frozen_string_literal: true

module Faturamento
  # Calcula estatÃ­sticas para um dia especÃ­fico
  #
  # Retorna:
  # - resumo: estatÃ­sticas gerais do dia
  # - comparacao: comparaÃ§Ã£o com mÃ©dia histÃ³rica
  # - detalhamento: breakdown por meio de pagamento, tipo de pessoa, perfil
  # - navegacao: links para dias anterior/seguinte e mÃªs atual
  #
  class EstatisticasDia
    def initialize(data:)
      @data = data.to_date
      @ano = @data.year
      @mes = @data.month
      @dia = @data.day
    end

    def call
      carregar_dados

      {
        resumo: calcular_resumo,
        comparacao: calcular_comparacao,
        detalhamento: calcular_detalhamento,
        navegacao: calcular_navegacao
      }
    end

    private

    attr_reader :data, :ano, :mes, :dia

    def carregar_dados
      @dados_total = Queries.faturamento_total(data, data)

      @dados_por_meio = Queries.faturamento_por_meio(data, data)
      @dados_por_tipo_pessoa = Queries.faturamento_por_tipo_pessoa(data, data)
      @dados_por_perfil = Queries.faturamento_por_perfil(data, data)
    end

    def calcular_resumo
      total_faturas = @dados_total[:quantidade]
      total_recebido = @dados_total[:total]
      ticket_medio = Calculations.calcular_ticket_medio(total_recebido, total_faturas)

      {
        data: data,
        total_faturas: total_faturas,
        total_recebido: total_recebido,
        ticket_medio: ticket_medio,
        por_meio: @dados_por_meio
      }
    end

    def calcular_comparacao
      media_historica = media_historica_para_dia
      total_recebido = @dados_total[:total]

      comparacao = Calculations.calcular_comparacao(total_recebido, media_historica)

      {
        media_historica: media_historica,
        diferenca: comparacao[:diferenca],
        percentual: comparacao[:percentual],
        performance: comparacao[:performance]
      }
    end

    def calcular_detalhamento
      {
        por_tipo_pessoa: @dados_por_tipo_pessoa,
        por_perfil: @dados_por_perfil
      }
    end

    def calcular_navegacao
      proximo_dia = data + 1.day

      {
        dia_anterior: data - 1.day,
        dia_seguinte: Periods.data_valida?(proximo_dia) ? proximo_dia : nil,
        mes_atual: { ano: ano, mes: mes }
      }
    end

    def media_historica_para_dia
      medias = MediasPorDiaDoMes.new(
        meses_atras: 12,
        excluir_mes_atual: Periods.mes_atual?(ano, mes)
      ).call

      medias[dia] || 0.0
    end
  end
end
