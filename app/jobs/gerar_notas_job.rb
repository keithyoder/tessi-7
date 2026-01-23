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
    puts "=" * 80
    puts "Emissão de NFCom - Resumo"
    puts "=" * 80
    puts "Sucesso: #{resultado[:success_count]}"
    puts "Erros: #{resultado[:error_count]}"
    puts "=" * 80
    
    return unless resultado[:erros].any?

    puts "\nErros:"
    resultado[:erros].each do |erro|
      puts "  - Fatura ##{erro[:fatura_id]}: #{erro[:mensagem]}"
    end
  end

  def exibir_erro_validacao(erro)
    puts "=" * 80
    puts "Erro de validação: #{erro.message}"
    puts "=" * 80
  end
end