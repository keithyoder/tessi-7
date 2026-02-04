# frozen_string_literal: true

module Faturamento
  # Calcula estatísticas para um dia específico
  #
  # Retorna:
  # - resumo: estatísticas gerais do dia
  # - comparacao: comparação com média histórica
  # - detalhamento: breakdown por meio de pagamento, etc.
  #
  class EstatisticasDia
    def initialize(data:)
      @data = data.to_date
      @ano = @data.year
      @mes = @data.month
      @dia = @data.day
    end

    def call
      {
        resumo: calcular_resumo,
        comparacao: calcular_comparacao,
        detalhamento: calcular_detalhamento,
        navegacao: calcular_navegacao
      }
    end

    private

    attr_reader :data, :ano, :mes, :dia

    def calcular_resumo
      faturas = Fatura.where(liquidacao: data)

      total_faturas = faturas.count
      total_recebido = faturas.sum(:valor_liquidacao).to_f

      # Breakdown por meio de liquidação
      por_meio = faturas.group(:meio_liquidacao).sum(:valor_liquidacao)

      {
        data: data,
        total_faturas: total_faturas,
        total_recebido: total_recebido,
        ticket_medio: total_faturas.positive? ? (total_recebido / total_faturas).round(2) : 0.0,
        por_meio: por_meio.transform_keys { |k| Fatura.meio_liquidacoes.key(k) || 'Desconhecido' }
      }
    end

    def calcular_comparacao
      media_historica = media_historica_para_dia
      total_recebido = calcular_resumo[:total_recebido]

      diferenca = total_recebido - media_historica
      percentual = media_historica.positive? ? (diferenca / media_historica * 100) : 0.0

      {
        media_historica: media_historica,
        diferenca: diferenca,
        percentual: percentual,
        performance: diferenca >= 0 ? :acima : :abaixo
      }
    end

    def calcular_detalhamento
      faturas = Fatura.where(liquidacao: data)

      # Por tipo de pessoa
      por_tipo_pessoa = faturas
        .joins(contrato: :pessoa)
        .group('pessoas.tipo')
        .count
        .transform_keys { |tipo| Pessoa.tipos.key(tipo) || 'Desconhecido' }

      # Por pagamento perfil
      por_perfil = faturas
        .joins(:pagamento_perfil)
        .group('pagamento_perfis.nome')
        .sum(:valor_liquidacao)

      {
        por_tipo_pessoa: por_tipo_pessoa,
        por_perfil: por_perfil
      }
    end

    def calcular_navegacao
      {
        dia_anterior: data - 1.day,
        dia_seguinte: data < Date.current ? data + 1.day : nil,
        mes_atual: { ano: ano, mes: mes }
      }
    end

    def media_historica_para_dia
      # Usa o mesmo serviço que o mês usa
      medias = MediasPorDiaDoMes.new(
        meses_atras: 12,
        excluir_mes_atual: mes_atual?
      ).call

      medias[dia] || 0.0
    end

    def mes_atual?
      ano == Date.current.year && mes == Date.current.month
    end
  end
end
