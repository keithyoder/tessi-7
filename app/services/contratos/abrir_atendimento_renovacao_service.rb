# frozen_string_literal: true

module Contratos
  # Abre (ou reaproveita) um Atendimento para controlar a impressão/envio
  # do carnê de boletos após a renovação de um contrato.
  #
  # Idempotente: se já existir um atendimento aberto dessa classificação
  # para o contrato, reaproveita — evita duplicar atendimentos quando a
  # renovação roda mais de uma vez antes do carnê ser entregue.

  class AbrirAtendimentoRenovacaoService
    def self.call(contrato:, responsavel:, aberto_por:)
      new(contrato:, responsavel:, aberto_por:).call
    end

    def initialize(contrato:, responsavel:, aberto_por:)
      @contrato = contrato
      @responsavel = responsavel
      @aberto_por = aberto_por
    end

    def call
      contrato.pessoa.atendimentos.where(
        fechamento: nil,
        contrato_id: contrato.id,
        classificacao_id: Classificacao::ENVIO_BOLETOS_ID
      ).first_or_create! do |atendimento|
        atendimento.contrato = contrato
        atendimento.responsavel = responsavel
        atendimento.aberto_por = aberto_por
      end
    end

    private

    attr_reader :contrato, :responsavel, :aberto_por
  end
end
