# frozen_string_literal: true

module Contratos
  # Serviço para renovar múltiplos contratos em lote.
  #
  # Responsável por:
  # - Buscar contratos elegíveis
  # - Aplicar regras de elegibilidade
  # - Processar renovações
  # - Retornar resultados
  #
  # Uso:
  #   resultado = Contratos::RenovacaoEmLoteService.new(
  #     pagamento_perfil_id: 1
  #   ).call
  #
  #   resultado.sucesso   # => ["João Silva", "Maria Santos"]
  #   resultado.ignorados # => ["Pedro Costa"]
  #   resultado.erros     # => {"Ana Lima" => "Erro ao gerar faturas"}
  #
  class RenovacaoEmLoteService
    attr_reader :pagamento_perfil_id, :meses_por_fatura

    Resultado = Struct.new(:sucesso, :ignorados, :erros, keyword_init: true) do
      def total_renovados
        sucesso.size
      end

      def total_ignorados
        ignorados.size
      end

      def total_erros
        erros.size
      end
    end

    def initialize(pagamento_perfil_id:, meses_por_fatura: 1)
      @pagamento_perfil_id = pagamento_perfil_id
      @meses_por_fatura = meses_por_fatura
      @sucesso = []
      @ignorados = []
      @erros = {}
    end

    def call
      contratos_candidatos.find_each do |contrato|
        processar_contrato(contrato)
      end

      Resultado.new(
        sucesso: @sucesso,
        ignorados: @ignorados,
        erros: @erros
      )
    end

    private

    def contratos_candidatos
      Contrato.includes(:pessoa, :plano)
        .where(pagamento_perfil_id: pagamento_perfil_id)
        .order('pessoas.nome')
        .renovaveis
    end

    def processar_contrato(contrato)
      unless elegivel?(contrato)
        @ignorados << contrato.pessoa.nome
        return
      end

      renovar_contrato(contrato)
    rescue StandardError => e
      @erros[contrato.pessoa.nome] = e.message
    end

    def elegivel?(contrato)
      contrato.faturas.inadimplentes.count <= 1 &&
        contrato.faturas.a_vencer.one?
    end

    def renovar_contrato(contrato)
      faturas_geradas = Contratos::RenovarService.new(
        contrato: contrato,
        meses_por_fatura: meses_por_fatura
      ).call

      @sucesso << contrato.pessoa.nome if faturas_geradas.present?
    end
  end
end
