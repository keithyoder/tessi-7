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
  # Este serviço NÃO realiza rateio parcial de mês.
  #
  class GerarService
    InvalidParams = Class.new(StandardError)
    MissingPagamentoPerfil = Class.new(StandardError)

    def self.call(contrato:, quantidade: 1, meses_por_fatura: 1)
      new(contrato, quantidade, meses_por_fatura).call
    end

    def initialize(contrato, quantidade, meses_por_fatura)
      @contrato         = contrato
      @quantidade       = quantidade.to_i
      @meses_por_fatura = (meses_por_fatura.presence || 1).to_i
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        inicializar_estado
        gerar_faturas
      end
    end

    private

    attr_reader :contrato, :quantidade, :meses_por_fatura

    # ----------------------------------------------------------------------
    # Inicialização de estado
    # ----------------------------------------------------------------------

    def inicializar_estado
      @parcela_atual =
        contrato.faturas.maximum(:parcela) || 0

      @nossonumero_atual =
        contrato.pagamento_perfil.proximo_nosso_numero.to_i

      @ultima_fatura =
        contrato.faturas.order(:periodo_fim).last
    end

    # ----------------------------------------------------------------------
    # Execução principal
    # ----------------------------------------------------------------------

    def gerar_faturas
      Array.new(quantidade) { gerar_proxima_fatura }
    end

    def gerar_proxima_fatura
      @parcela_atual     += 1
      @nossonumero_atual += 1

      inicio = proximo_periodo_inicio
      fim    = proximo_periodo_fim(inicio)

      fatura = contrato.faturas.create!(
        periodo_inicio: inicio,
        periodo_fim: fim,
        valor: valor_atual(@parcela_atual),
        valor_original: valor_atual(@parcela_atual),
        parcela: @parcela_atual,
        nossonumero: @nossonumero_atual.to_s,
        pagamento_perfil: contrato.pagamento_perfil,
        vencimento: fim,
        vencimento_original: fim
      )

      @ultima_fatura = fatura
      fatura
    end

    # ----------------------------------------------------------------------
    # Domínio
    # ----------------------------------------------------------------------

    def proximo_periodo_inicio
      @ultima_fatura ? @ultima_fatura.periodo_fim + 1.day : contrato.adesao
    end

    def proximo_periodo_fim(inicio)
      fim_base = inicio.advance(months: meses_por_fatura)

      if inicio == inicio.end_of_month
        fim_base.end_of_month
      else
        fim_base - 1.day
      end
    end

    def valor_atual(parcela)
      (contrato.mensalidade * meses_por_fatura) + parcela_instalacao(parcela)
    end

    def parcela_instalacao(parcela)
      return 0 unless aplica_instalacao?(parcela)

      (contrato.valor_instalacao / contrato.parcelas_instalacao).round(2)
    end

    def aplica_instalacao?(parcela)
      contrato.parcelas_instalacao.to_i.positive? &&
        parcela <= contrato.parcelas_instalacao
    end

    # ----------------------------------------------------------------------
    # Validações
    # ----------------------------------------------------------------------

    def validate!
      raise InvalidParams, 'Quantidade inválida' if quantidade <= 0
      raise InvalidParams, 'Meses por fatura inválido' if meses_por_fatura <= 0
      raise MissingPagamentoPerfil if contrato.pagamento_perfil.blank?
    end
  end
end
