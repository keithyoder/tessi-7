# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GerarNotasJob, type: :job do
  let(:service_resultado) do
    {
      success_count: 5,
      error_count: 2,
      faturas_processadas: [
        { fatura_id: 1, nfcom_numero: 123, status: 'success' },
        { fatura_id: 2, nfcom_numero: 124, status: 'success' }
      ],
      erros: [
        { fatura_id: 3, mensagem: 'Erro na SEFAZ' },
        { fatura_id: 4, mensagem: 'Documento inválido' }
      ]
    }
  end

  before do
    travel_to Date.new(2026, 1, 23)
    allow(Nfcom::EmitirLoteService).to receive(:call).and_return(service_resultado)
  end

  describe '#perform' do
    context 'quando não são fornecidas datas' do
      it 'usa o mês atual como padrão' do
        described_class.perform_now

        expect(Nfcom::EmitirLoteService).to have_received(:call).with(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 31)
        )
      end

      it 'retorna o resultado do serviço' do
        resultado = described_class.perform_now

        expect(resultado).to eq(service_resultado)
      end

      it 'exibe resumo com contadores' do
        output = capture_stdout do
          described_class.perform_now
        end

        expect(output).to include('Emissão de NFCom - Resumo')
        expect(output).to include('Sucesso: 5')
        expect(output).to include('Erros: 2')
      end

      it 'exibe detalhes dos erros' do
        output = capture_stdout do
          described_class.perform_now
        end

        expect(output).to include('Fatura #3: Erro na SEFAZ')
        expect(output).to include('Fatura #4: Documento inválido')
      end
    end

    context 'quando são fornecidas datas customizadas' do
      it 'usa as datas fornecidas' do
        described_class.perform_now(
          data_inicio: '2026-01-15',
          data_fim: '2026-01-20'
        )

        expect(Nfcom::EmitirLoteService).to have_received(:call).with(
          data_inicio: Date.new(2026, 1, 15),
          data_fim: Date.new(2026, 1, 20)
        )
      end

      it 'aceita datas como objetos Date' do
        described_class.perform_now(
          data_inicio: Date.new(2026, 1, 15),
          data_fim: Date.new(2026, 1, 20)
        )

        expect(Nfcom::EmitirLoteService).to have_received(:call).with(
          data_inicio: Date.new(2026, 1, 15),
          data_fim: Date.new(2026, 1, 20)
        )
      end
    end

    context 'quando não há erros' do
      let(:service_resultado_sem_erros) do
        {
          success_count: 10,
          error_count: 0,
          faturas_processadas: [],
          erros: []
        }
      end

      before do
        allow(Nfcom::EmitirLoteService).to receive(:call).and_return(service_resultado_sem_erros)
      end

      it 'não exibe seção de erros' do
        output = capture_stdout do
          described_class.perform_now
        end

        expect(output).to include('Sucesso: 10')
        expect(output).to include('Erros: 0')
        expect(output).not_to include('Fatura #')
      end
    end

    context 'quando ocorre erro de validação' do
      before do
        allow(Nfcom::EmitirLoteService).to receive(:call).and_raise(
          ArgumentError,
          'data_inicio deve estar no mês atual'
        )
      end

      it 'captura e relança o erro' do
        expect do
          described_class.perform_now(
            data_inicio: '2025-12-01',
            data_fim: '2025-12-31'
          )
        end.to raise_error(ArgumentError, 'data_inicio deve estar no mês atual')
      end

      it 'exibe mensagem de erro de validação' do
        output = capture_stdout do
          described_class.perform_now(
            data_inicio: '2025-12-01',
            data_fim: '2025-12-31'
          )
        rescue ArgumentError
          # Expected
        end

        expect(output).to include('Erro de validação: data_inicio deve estar no mês atual')
      end

      it 'registra no log' do
        allow(Rails.logger).to receive(:error)

        begin
          described_class.perform_now(
            data_inicio: '2025-12-01',
            data_fim: '2025-12-31'
          )
        rescue ArgumentError
          # Expected
        end

        expect(Rails.logger).to have_received(:error).with(
          'Erro de validação ao gerar NFCom: data_inicio deve estar no mês atual'
        )
      end
    end

    context 'quando ocorre erro inesperado' do
      before do
        allow(Nfcom::EmitirLoteService).to receive(:call).and_raise(
          StandardError,
          'Erro de conexão'
        )
      end

      it 'captura e relança o erro' do
        expect do
          described_class.perform_now
        end.to raise_error(StandardError, 'Erro de conexão')
      end

      it 'registra no log com backtrace' do
        allow(Rails.logger).to receive(:error)

        begin
          described_class.perform_now
        rescue StandardError
          # Expected
        end

        expect(Rails.logger).to have_received(:error).with(
          /Erro inesperado ao gerar NFCom: Erro de conexão/
        )
      end
    end

    context 'quando executado em background' do
      it 'enfileira o job' do
        expect do
          described_class.perform_later
        end.to have_enqueued_job(described_class)
      end

      it 'enfileira o job com parâmetros' do
        expect do
          described_class.perform_later(
            data_inicio: '2026-01-01',
            data_fim: '2026-01-31'
          )
        end.to have_enqueued_job(described_class).with(
          data_inicio: '2026-01-01',
          data_fim: '2026-01-31'
        )
      end

      it 'usa a fila default' do
        expect(described_class.new.queue_name).to eq('default')
      end
    end
  end

  # Helper to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
