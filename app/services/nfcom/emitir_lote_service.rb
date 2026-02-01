# frozen_string_literal: true

module Nfcom
  # Serviço para emitir NFCom em lote para faturas liquidadas em um período
  #
  # @param data_inicio [Date] data inicial do período
  # @param data_fim [Date] data final do período
  #
  # Uso:
  #   resultado = Nfcom::EmitirLoteService.call(
  #     data_inicio: Date.new(2026, 1, 1),
  #     data_fim: Date.new(2026, 1, 31)
  #   )
  #
  #   puts "Sucesso: #{resultado[:success_count]}"
  #   puts "Erros: #{resultado[:error_count]}"
  #
  class EmitirLoteService
    # Número de dias antes do início do mês atual permitidos
    DIAS_RETROATIVOS_PERMITIDOS = 5

    def self.call(data_inicio:, data_fim:)
      new(data_inicio, data_fim).call
    end

    def initialize(data_inicio, data_fim)
      @data_inicio = data_inicio.to_date
      @data_fim = data_fim.to_date
      @emitter = Nfcom::Emitter.new
      @results = {
        success_count: 0,
        error_count: 0,
        faturas_processadas: [],
        erros: []
      }
    end

    def call
      validate_dates!

      faturas = buscar_faturas

      Rails.logger.info "Iniciando emissão em lote de #{faturas.count} NFCom"
      Rails.logger.info "Período: #{data_inicio} até #{data_fim}"

      faturas.find_each do |fatura|
        processar_fatura(fatura)
      end

      Rails.logger.info "Emissão em lote concluída: #{results[:success_count]} sucesso, #{results[:error_count]} erros"

      results
    end

    private

    attr_reader :data_inicio, :data_fim, :emitter, :results

    def validate_dates!
      raise ArgumentError, 'data_inicio não pode ser posterior a data_fim' if data_inicio > data_fim

      # Permite datas até DIAS_RETROATIVOS_PERMITIDOS antes do início do mês atual
      earliest_allowed = Date.current.beginning_of_month - DIAS_RETROATIVOS_PERMITIDOS.days

      if data_inicio < earliest_allowed
        raise ArgumentError,
              "data_inicio (#{data_inicio}) não pode ser anterior a #{I18n.l(earliest_allowed)}"
      end

      # Não permite datas no futuro
      return unless data_fim > Date.current

      raise ArgumentError,
            "data_fim (#{data_fim}) não pode ser posterior à data atual (#{I18n.l(Date.current)})"
    end

    def buscar_faturas
      range = data_inicio..data_fim
      Fatura.notas_a_emitir(range).com_associacoes.order(:liquidacao)
    end

    def processar_fatura(fatura)
      nfcom_record = emitter.emitir(fatura.id)

      if nfcom_record.status == 'authorized'
        registrar_sucesso(fatura, nfcom_record)
      else
        registrar_erro(fatura, nfcom_record.mensagem_sefaz || 'Rejeitada sem mensagem')
      end
    rescue Nfcom::Errors::NotaRejeitada => e
      registrar_erro(fatura, "#{e.codigo}: #{e.motivo}")
    rescue StandardError => e
      registrar_erro(fatura, e.message)
      Rails.logger.error(
        "Erro inesperado ao emitir NFCom para fatura #{fatura.id}: " \
        "#{e.message}\n#{e.backtrace.join("\n")}"
      )
    end

    def registrar_sucesso(fatura, nfcom_record)
      results[:success_count] += 1
      results[:faturas_processadas] << {
        fatura_id: fatura.id,
        nfcom_numero: nfcom_record.numero,
        status: 'success'
      }

      Rails.logger.info "✓ Fatura ##{fatura.id} - NFCom ##{nfcom_record.numero} - Autorizada"
    end

    def registrar_erro(fatura, mensagem)
      results[:error_count] += 1
      results[:erros] << {
        fatura_id: fatura.id,
        mensagem: mensagem
      }

      Rails.logger.warn "✗ Fatura ##{fatura.id} - Erro: #{mensagem}"
    end
  end
end
