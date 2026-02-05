# frozen_string_literal: true

module Faturamento
  # Cálculos compartilhados entre os serviços de estatísticas
  module Calculations
    module_function

    # Calcula diferença percentual entre dois valores
    #
    # @param atual [Numeric] valor atual/real
    # @param esperado [Numeric] valor esperado/base
    # @return [Float] percentual de diferença
    def calcular_percentual(atual, esperado)
      return 0.0 if esperado.zero?

      diferenca = atual - esperado
      ((diferenca.to_f / esperado) * 100).round(2)
    end

    # Calcula diferença e percentual em um único hash
    #
    # @param atual [Numeric] valor atual/real
    # @param esperado [Numeric] valor esperado/base
    # @return [Hash] com :diferenca, :percentual, :performance
    def calcular_comparacao(atual, esperado)
      diferenca = atual - esperado
      percentual = calcular_percentual(atual, esperado)

      {
        diferenca: diferenca,
        percentual: percentual,
        performance: diferenca >= 0 ? :acima : :abaixo
      }
    end

    # Calcula ticket médio
    #
    # @param total [Numeric] valor total
    # @param quantidade [Integer] quantidade de itens
    # @return [Float] ticket médio arredondado
    def calcular_ticket_medio(total, quantidade)
      return 0.0 if quantidade.zero?

      (total.to_f / quantidade).round(2)
    end

    # Monta estrutura padrão de resumo
    #
    # @param total_recebido [Numeric]
    # @param total_esperado [Numeric]
    # @param total_faturas [Integer]
    # @return [Hash] estrutura de resumo padronizada
    def build_resumo(total_recebido:, total_esperado:, total_faturas: 0, **extras)
      comparacao = calcular_comparacao(total_recebido, total_esperado)

      {
        total_recebido: total_recebido,
        total_esperado: total_esperado,
        diferenca: comparacao[:diferenca],
        percentual_diferenca: comparacao[:percentual],
        performance: comparacao[:performance],
        total_faturas: total_faturas
      }.merge(extras)
    end

    # Estrutura de resumo vazia
    def resumo_vazio(**extras)
      build_resumo(
        total_recebido: 0.0,
        total_esperado: 0.0,
        total_faturas: 0,
        **extras
      )
    end
  end
end
