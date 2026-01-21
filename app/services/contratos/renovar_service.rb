module Contratos
  # Serviço para renovar um contrato gerando as faturas necessárias.
  #
  # Este serviço calcula automaticamente quantas faturas precisam ser geradas
  # para cobrir o período restante do contrato até o final do prazo, considerando:
  # - A data da última fatura existente ou a data de adesão do contrato;
  # - O prazo total do contrato (`contrato.prazo_meses`);
  # - A quantidade de meses cobertos por fatura (`meses_por_fatura`).
  #
  # Uso típico:
  #
  #   contrato = Contrato.find(1)
  #   Contratos::RenovarService.new(contrato: contrato, meses_por_fatura: 3).call
  #
  # Isso irá gerar automaticamente as faturas restantes do contrato em blocos de 3 meses.
  #
  class RenovarService
    attr_reader :contrato, :meses_por_fatura

    # Inicializa o serviço
    #
    # @param contrato [Contrato] contrato a ser renovado
    # @param meses_por_fatura [Integer] quantidade de meses cobertos por cada fatura (default: 1)
    def initialize(contrato:, meses_por_fatura: 1)
      @contrato = contrato
      @meses_por_fatura = meses_por_fatura.to_i.positive? ? meses_por_fatura.to_i : 1
    end

    # Executa a renovação do contrato
    #
    # Gera automaticamente as faturas necessárias para cobrir o período restante
    # até o final do prazo do contrato.
    #
    # @return [Array<Fatura>, nil] faturas geradas ou nil se não houver meses restantes
    def call
      meses_restantes = months_between(inicio_proximo_periodo + 1.day, fim_contrato)
      return if meses_restantes.to_i <= 0

      gerar_faturas_necessarias(meses_restantes)
    end

    private

    def inicio_proximo_periodo
      ultima_fatura = contrato.faturas.order(:periodo_fim).last
      ultima_fatura ? ultima_fatura.periodo_fim : contrato.adesao - 1.day
    end

    def fim_contrato
      Date.today.advance(months: contrato.prazo_meses)
    end

    def gerar_faturas_necessarias(meses_restantes)
      quantidade = (meses_restantes.to_f / meses_por_fatura).ceil
      Faturas::GerarService.call(
        contrato: contrato,
        quantidade: quantidade,
        meses_por_fatura: meses_por_fatura
      )
    end

    # Calcula o número de meses entre duas datas
    #
    # @param inicio [Date] data inicial
    # @param fim [Date] data final
    # @return [Integer] quantidade de meses completos entre as datas
    def months_between(inicio, fim)
      (fim.year * 12 + fim.month) - (inicio.year * 12 + inicio.month) + (fim.day >= inicio.day ? 0 : -1)
    end
  end
end
