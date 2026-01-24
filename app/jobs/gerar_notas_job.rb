# frozen_string_literal: true

class GerarNotasJob < ApplicationJob
  queue_as :default

  def perform(data_inicio: nil, data_fim: nil)
    # Default to current month if no dates provided
    inicio, fim = definir_periodo(data_inicio, data_fim)

    resultado = Nfcom::EmitirLoteService.call(
      data_inicio: inicio,
      data_fim: fim
    )

    exibir_resumo(resultado)

    resultado
  rescue ArgumentError => e
    Rails.logger.error "Erro de validação ao gerar NFCom: #{e.message}"
    exibir_erro_validacao(e)
    raise
  rescue StandardError => e
    Rails.logger.error "Erro inesperado ao gerar NFCom: #{e.message}\n#{e.backtrace.join("\n")}"
    raise
  end

  private

  def definir_periodo(data_inicio, data_fim)
    if data_inicio && data_fim
      [Date.parse(data_inicio.to_s), Date.parse(data_fim.to_s)]
    else
      # Use current month by default
      [Date.current.beginning_of_month, Date.current.end_of_month]
    end
  end

  def exibir_resumo(resultado)
    Rails.logger.debug '=' * 80
    Rails.logger.debug 'Emissão de NFCom - Resumo'
    Rails.logger.debug '=' * 80
    Rails.logger.debug { "Sucesso: #{resultado[:success_count]}" }
    Rails.logger.debug { "Erros: #{resultado[:error_count]}" }
    Rails.logger.debug '=' * 80

    return unless resultado[:erros].any?

    Rails.logger.debug "\nErros:"
    resultado[:erros].each do |erro|
      Rails.logger.debug "  - Fatura ##{erro[:fatura_id]}: #{erro[:mensagem]}"
    end
  end

  def exibir_erro_validacao(erro)
    Rails.logger.debug '=' * 80
    Rails.logger.debug { "Erro de validação: #{erro.message}" }
    Rails.logger.debug '=' * 80
  end
end
