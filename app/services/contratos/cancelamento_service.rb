# frozen_string_literal: true

module Contratos
  # Serviço responsável por aplicar todas as regras de cancelamento de um contrato.
  #
  # Regras aplicadas no cancelamento:
  #
  # 1) Faturas FUTURAS não pagas e não registradas
  #    → São removidas (destroy)
  #
  # 2) Faturas FUTURAS não pagas, porém já registradas
  #    → São marcadas como canceladas (campo cancelamento)
  #
  # 3) Fatura PARCIAL (mês em que ocorre o cancelamento)
  #    → Tem seu valor ajustado proporcionalmente ao período utilizado
  #
  # Importante:
  # - O cálculo de pró-rata NÃO é feito aqui.
  # - O cálculo é delegado ao serviço Faturas::PeriodoUtilizado.
  #
  # Este serviço NÃO:
  # - Gera novas faturas
  # - Altera pagamento_perfil
  # - Recalcula vencimentos
  #
  class CancelamentoService
    def self.call(contrato:, data_cancelamento:)
      new(contrato, data_cancelamento).call
    end

    def initialize(contrato, data_cancelamento)
      @contrato = contrato
      @data_cancelamento = data_cancelamento.to_date
    end

    def call
      ActiveRecord::Base.transaction do
        remover_faturas_futuras_nao_registradas
        cancelar_faturas_futuras_registradas
        ajustar_faturas_parciais
      end
    end

    private

    attr_reader :contrato, :data_cancelamento

    # Remove faturas que ainda não foram pagas nem registradas
    # e cujo período inicia após a data de cancelamento.
    #
    # Essas faturas ainda não possuem efeitos fiscais ou financeiros
    # e podem ser excluídas com segurança.
    #
    def remover_faturas_futuras_nao_registradas
      contrato.faturas
        .em_aberto
        .nao_registradas
        .where(periodo_inicio: data_cancelamento..)
        .destroy_all
    end

    # Marca como canceladas as faturas que:
    # - Não foram pagas
    # - Já foram registradas (ex: boleto emitido)
    # - Referem-se a períodos após o cancelamento
    #
    # Essas faturas NÃO devem ser apagadas por motivos fiscais,
    # apenas sinalizadas como canceladas.
    #
    def cancelar_faturas_futuras_registradas
      contrato.faturas
        .registradas
        .em_aberto
        .where(periodo_inicio: data_cancelamento..)
        .update_all(cancelamento: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    # Ajusta o valor da fatura referente ao período em que
    # o cancelamento ocorreu.
    #
    # SEMÂNTICA DO CANCELAMENTO:
    # - data_cancelamento representa o primeiro dia SEM serviço
    # - Exemplo: cancelamento em 25/01 → último dia de serviço foi 24/01
    # - Cálculo: de periodo_inicio até (data_cancelamento - 1 dia)
    #
    # Exemplo:
    # - Período da fatura: 10/01 a 09/02
    # - Cancelamento em: 25/01
    # - Dias cobrados: 10/01 a 24/01 (15 dias)
    #
    def ajustar_faturas_parciais
      faturas_parciais.each do |fatura|
        # Calcula dias utilizados considerando o período real da fatura
        dias_no_periodo = (fatura.periodo_fim - fatura.periodo_inicio).to_i + 1
        dias_utilizados = (data_cancelamento - fatura.periodo_inicio).to_i

        fracao_utilizada = [dias_utilizados.to_d / dias_no_periodo, 1.to_d].min

        fatura.update!(
          valor: (fatura.valor_original * fracao_utilizada).round(2)
        )
      end
    end

    # Retorna as faturas cujo período engloba a data de cancelamento.
    #
    # Apenas faturas não pagas e não registradas podem ser ajustadas.
    #
    def faturas_parciais
      contrato.faturas
        .em_aberto
        .nao_registradas
        .where('? BETWEEN periodo_inicio AND periodo_fim', data_cancelamento)
    end
  end
end
