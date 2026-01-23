# frozen_string_literal: true

module Faturas
  # Serviço para atualizar o valor de uma fatura existente.
  #
  # Como não podemos simplesmente alterar o valor de uma fatura já registrada,
  # este serviço:
  # 1. Se a fatura está registrada (tem registro_id): cancela e cria uma nova
  # 2. Se a fatura não está registrada: deleta e cria uma nova
  #
  # @param fatura [Fatura] fatura a ser atualizada
  # @param novo_valor [Decimal] novo valor da fatura
  #
  # Uso:
  #   fatura = Fatura.find(123)
  #   nova_fatura = Faturas::AtualizarValorService.call(
  #     fatura: fatura,
  #     novo_valor: 150.00
  #   )
  #
  class AtualizarValorService
    def self.call(fatura:, novo_valor:)
      new(fatura, novo_valor).call
    end

    def initialize(fatura, novo_valor)
      @fatura = fatura
      @novo_valor = novo_valor
    end

    def call
      ActiveRecord::Base.transaction do
        # Cancela ou deleta a fatura antiga
        if fatura.registro_id.present?
          fatura.update!(cancelamento: Time.current)
        else
          fatura.destroy!
        end

        # Cria nova fatura com o novo valor
        criar_nova_fatura
      end
    end

    private

    attr_reader :fatura, :novo_valor

    def criar_nova_fatura
      fatura.contrato.faturas.create!(
        periodo_inicio: fatura.periodo_inicio,
        periodo_fim: fatura.periodo_fim,
        vencimento: fatura.vencimento,
        vencimento_original: fatura.vencimento_original || fatura.vencimento,
        valor: novo_valor,
        valor_original: fatura.valor,
        parcela: fatura.parcela,
        nossonumero: fatura.contrato.pagamento_perfil.proximo_nosso_numero.to_s,
        pagamento_perfil: fatura.pagamento_perfil
      )
    end
  end
end