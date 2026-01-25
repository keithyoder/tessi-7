# frozen_string_literal: true

module Atendimentos
  # Serviço para criar um atendimento junto com seu primeiro detalhe.
  #
  # Este serviço garante que tanto o atendimento quanto o detalhe inicial
  # sejam criados de forma atômica (tudo ou nada).
  #
  # Uso:
  #   result = Atendimentos::CriarService.call(
  #     atendimento_params: { pessoa_id: 1, classificacao_id: 2, ... },
  #     detalhe_tipo: 'Presencial',
  #     detalhe_descricao: 'Cliente relatou problema na conexão',
  #     atendente: current_user
  #   )
  #
  #   if result[:success]
  #     atendimento = result[:atendimento]
  #     detalhe = result[:detalhe]
  #   else
  #     errors = result[:atendimento].errors
  #   end
  #
  class CriarService
    def self.call(atendimento_params:, detalhe_tipo:, detalhe_descricao:, atendente:)
      new(atendimento_params, detalhe_tipo, detalhe_descricao, atendente).call
    end

    def initialize(atendimento_params, detalhe_tipo, detalhe_descricao, atendente)
      @atendimento_params = atendimento_params
      @detalhe_tipo = detalhe_tipo
      @detalhe_descricao = detalhe_descricao
      @atendente = atendente
    end

    def call
      atendimento = nil
      detalhe = nil
      success = false

      ActiveRecord::Base.transaction do
        atendimento = Atendimento.create!(atendimento_params)
        detalhe = criar_detalhe_inicial(atendimento)
        success = true
      end

      {
        success: success,
        atendimento: atendimento,
        detalhe: detalhe
      }
    rescue ActiveRecord::RecordInvalid => e
      {
        success: false,
        atendimento: e.record.is_a?(Atendimento) ? e.record : atendimento || Atendimento.new(atendimento_params),
        detalhe: e.record.is_a?(AtendimentoDetalhe) ? e.record : detalhe
      }
    end

    private

    attr_reader :atendimento_params, :detalhe_tipo, :detalhe_descricao, :atendente

    def criar_detalhe_inicial(atendimento)
      AtendimentoDetalhe.create!(
        atendimento: atendimento,
        atendente: atendente,
        tipo: normalizar_tipo(detalhe_tipo),
        descricao: detalhe_descricao
      )
    end

    # Converte o tipo de string ou inteiro para o símbolo correto
    def normalizar_tipo(tipo)
      return tipo if tipo.is_a?(Symbol) || (tipo.is_a?(String) && !tipo.match?(/^\d+$/))

      # Se for um número (como string ou integer), converte usando o enum
      AtendimentoDetalhe.tipos.key(tipo.to_i)
    end
  end
end
