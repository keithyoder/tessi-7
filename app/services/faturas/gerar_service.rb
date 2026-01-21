# frozen_string_literal: true

module Faturas
  # Serviço para gerar faturas completas para um contrato.
  #
  # Cada fatura pode cobrir 1 ou mais meses contratuais.
  #
  # Exemplos:
  # - meses_por_fatura = 1 → Jan 10 – Feb 9
  # - meses_por_fatura = 3 → Jan 10 – Apr 9
  #
  # Este serviço NÃO realiza rateio parcial de mês. Para isso, use Faturas::PeriodoUtilizado.
  #
  class GerarService
    # Interface de chamada principal
    #
    # @param contrato [Contrato] contrato para gerar faturas
    # @param quantidade [Integer] quantidade de faturas a gerar
    # @param meses_por_fatura [Integer] meses cobertos por cada fatura
    # @return [Array<Fatura>] faturas geradas
    def self.call(contrato:, quantidade: 1, meses_por_fatura: 1)
      new(contrato, quantidade, meses_por_fatura).call
    end

    def initialize(contrato, quantidade, meses_por_fatura)
      @contrato          = contrato
      @quantidade        = quantidade.to_i
      @meses_por_fatura  = (meses_por_fatura.presence || 1).to_i
    end

    # Executa a geração das faturas
    #
    # Retorna nil se quantidade ou meses_por_fatura forem <= 0
    def call # rubocop:disable Metrics/MethodLength
      return if quantidade <= 0 || meses_por_fatura <= 0

      faturas_geradas = []

      ActiveRecord::Base.transaction do
        # Inicializa a próxima parcela e o próximo nosso número
        parcela_atual      = contrato.faturas.maximum(:parcela) || 0
        nossonumero_atual  = contrato.pagamento_perfil.proximo_nosso_numero

        quantidade.times do
          parcela_atual += 1
          nossonumero_atual += 1

          fatura = gerar_proxima_fatura(parcela_atual, nossonumero_atual)
          faturas_geradas << fatura
        end
      end

      faturas_geradas
    end

    private

    attr_reader :contrato, :quantidade, :meses_por_fatura

    # Gera a próxima fatura usando a parcela e nossonumero informados
    def gerar_proxima_fatura(parcela, nossonumero) # rubocop:disable Metrics/MethodLength
      inicio = data_inicio_proxima_fatura
      fim    = fim_do_periodo(inicio)

      # Calcula valor da fatura considerando mensalidade e parcelas de instalação
      valor = valor_da_fatura(parcela)

      contrato.faturas.create!(
        periodo_inicio: inicio,
        periodo_fim: fim,
        valor: valor,
        valor_original: valor,
        parcela: parcela,
        nossonumero: nossonumero,
        pagamento_perfil: contrato.pagamento_perfil,
        vencimento: fim,
        vencimento_original: fim
      )
    end

    # Data de início do próximo período de fatura
    #
    # Se já houver faturas, começa um dia após a última fatura.
    # Caso contrário, inicia na data de adesão do contrato.
    def data_inicio_proxima_fatura
      ultima_fatura = contrato.faturas.order(:periodo_fim).last
      ultima_fatura ? ultima_fatura.periodo_fim + 1.day : contrato.adesao
    end

    # Data final do período da fatura
    #
    # Considera a quantidade de meses por fatura e subtrai 1 dia
    def fim_do_periodo(inicio)
      inicio.advance(months: meses_por_fatura) - 1.day
    end

    # Valor total da fatura considerando mensalidade e parcela de instalação
    def valor_da_fatura(parcela_num)
      contrato.mensalidade * meses_por_fatura + parcela_instalacao(parcela_num)
    end

    # Calcula a parcela de instalação para a fatura atual
    #
    # Só é aplicada nas primeiras faturas, de acordo com parcelas_instalacao
    def parcela_instalacao(parcela_num)
      if contrato.parcelas_instalacao.to_i.positive? && parcela_num <= contrato.parcelas_instalacao
        (contrato.valor_instalacao / contrato.parcelas_instalacao).round(2)
      else
        0
      end
    end
  end
end
