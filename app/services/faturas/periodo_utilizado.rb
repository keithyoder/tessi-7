# frozen_string_literal: true

module Faturas
  # Serviço responsável por calcular qual fração de um período mensal de
  # faturamento foi efetivamente utilizada, dado um intervalo de datas.
  #
  # === Intenção de negócio
  #
  # Este serviço existe para responder à seguinte pergunta:
  #
  #   "Dado um período mensal de cobrança e uma data de corte,
  #    qual porcentagem desse período deve ser faturada?"
  #
  # Ele é utilizado principalmente em cenários como:
  # - Cancelamento de contrato no meio do período
  # - Ajustes manuais de fatura
  # - Créditos ou estornos proporcionais
  #
  # IMPORTANTe: este serviço NÃO conhece Contrato, Plano ou Fatura.
  # Ele trabalha exclusivamente com datas e regras de tempo.
  #
  # === Definição do período
  #
  # O período de faturamento é sempre definido como:
  #
  #   [inicio, inicio + 1.month)
  #
  # Ou seja:
  # - Começa na data `inicio`
  # - Termina exatamente 1 mês depois
  # - A data final é EXCLUSIVA
  #
  # Exemplo:
  #
  #   inicio = 10/01
  #   periodo_fim = 10/02
  #
  # O último dia faturado é 09/02.
  #
  # === Regra de cálculo
  #
  # A fração utilizada é calculada como:
  #
  #   tempo_utilizado / tempo_total_do_periodo
  #
  # Onde:
  #
  #   tempo_utilizado = min(fim, periodo_fim) - inicio
  #   tempo_total     = periodo_fim - inicio
  #
  # O resultado é sempre limitado ao intervalo [0, 1].
  #
  # === Exemplos
  #
  #   PeriodoUtilizado.call(
  #     inicio: Date.new(2026, 1, 10),
  #     fim:    Date.new(2026, 1, 25)
  #   )
  #   # => ~0.48
  #
  #   PeriodoUtilizado.call(
  #     inicio: Date.new(2026, 1, 10),
  #     fim:    Date.new(2026, 2, 9)
  #   )
  #   # => ~0.97
  #
  #   PeriodoUtilizado.call(
  #     inicio: Date.new(2026, 1, 10),
  #     fim:    Date.new(2026, 3, 1)
  #   )
  #   # => 1.0
  #
  # === Garantias
  #
  # - Nunca retorna valor negativo
  # - Nunca retorna valor maior que 1
  # - Usa BigDecimal para evitar erros de ponto flutuante
  # - Não realiza arredondamento monetário
  #
  # === Responsabilidades fora deste serviço
  #
  # - Decidir quando aplicar a fração (Contrato / Fatura)
  # - Arredondar valores financeiros
  # - Persistir dados
  #
  class PeriodoUtilizado
    def self.call(inicio:, fim:)
      new(inicio, fim).call
    end

    def initialize(inicio, fim)
      @inicio = inicio.to_date
      @fim    = fim.to_date
    end

    # Executa o cálculo e retorna a fração do período utilizada.
    #
    # @return [BigDecimal] valor entre 0.0 e 1.0
    def call
      validar_periodo!

      periodo_fim = inicio + 1.month

      tempo_utilizado = [fim, periodo_fim].min - inicio
      tempo_total     = periodo_fim - inicio

      (tempo_utilizado.to_d / tempo_total).clamp(0.to_d, 1.to_d)
    end

    private

    attr_reader :inicio, :fim

    def validar_periodo!
      raise ArgumentError, 'Data final não pode ser anterior à data inicial' if fim < inicio
    end
  end
end
