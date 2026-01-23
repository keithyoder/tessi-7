# frozen_string_literal: true

module Faturas
  # Serviço para gerar faturas de um contrato.
  #
  # Cada fatura pode cobrir 1 ou mais meses contratuais.
  # Se houver cancelamento parcial, calcula a fração do período.
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
        Array.new(quantidade) { gerar_proxima_fatura }
      end
    end

    private

    attr_reader :contrato, :quantidade, :meses_por_fatura

    # ----------------------------------------------------------------------
    # Inicialização de estado
    # ----------------------------------------------------------------------

    def inicializar_estado
      @parcela_atual     = contrato.faturas.maximum(:parcela) || 0
      @nossonumero_atual = contrato.pagamento_perfil.proximo_nosso_numero.to_i
      @ultimo_vencimento = contrato.faturas.maximum(:vencimento) || (contrato.primeiro_vencimento - 1.month)
    end

    # ----------------------------------------------------------------------
    # Geração de faturas
    # ----------------------------------------------------------------------

    def gerar_proxima_fatura
      @parcela_atual     += 1
      @nossonumero_atual += 1

      # Calcula o próximo vencimento usando Calendario
      vencimento = Faturas::Calendario.avancar_meses(
        @ultimo_vencimento,
        contrato.dia_vencimento,
        meses: meses_por_fatura
      )

      # Calcula o período da fatura
      periodo = Faturas::Calendario.periodo(@ultimo_vencimento, vencimento)
      inicio  = periodo[:inicio]
      fim     = periodo[:fim]

      # Ajusta valor proporcional se houver cancelamento no meio do período
      valor = contrato.mensalidade * meses_por_fatura
      if contrato.cancelamento.present? && contrato.cancelamento.between?(inicio, fim)
        fracao = Faturas::PeriodoUtilizado.call(inicio: inicio, fim: contrato.cancelamento)
        valor = (valor * fracao).round(2)
      end

      # Soma parcela de instalação se aplicável
      valor += parcela_instalacao(@parcela_atual)

      fatura = contrato.faturas.create!(
        periodo_inicio: inicio,
        periodo_fim: fim,
        vencimento: vencimento,
        vencimento_original: vencimento,
        valor: valor,
        valor_original: valor,
        parcela: @parcela_atual,
        nossonumero: @nossonumero_atual.to_s,
        pagamento_perfil: contrato.pagamento_perfil
      )

      @ultimo_vencimento = vencimento
      fatura
    end

    # ----------------------------------------------------------------------
    # Instalação
    # ----------------------------------------------------------------------

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
