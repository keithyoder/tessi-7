# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Nfcom::EmitirLoteService, type: :service do
  let!(:contrato) do
    build(
      :contrato,
      adesao: Date.new(2026, 1, 10),
      primeiro_vencimento: Date.new(2026, 2, 10),
      emite_nf: true
    ).tap do |c|
      allow(c).to receive(:gerar_faturas_iniciais)
      c.save!
    end
  end

  let!(:fatura_paga) do
    create(
      :fatura,
      contrato: contrato,
      vencimento: Date.new(2026, 1, 10),
      liquidacao: Date.new(2026, 1, 15),
      valor: 100.00,
      valor_liquidacao: 100.00,
      nossonumero: '10001',
      parcela: 1,
      periodo_inicio: Date.new(2026, 1, 1),
      periodo_fim: Date.new(2026, 1, 31)
    )
  end

  let(:emitter) { instance_spy(Nfcom::Emitter) }
  let(:nfcom_record_autorizada) do
    instance_double(
      NfcomNota,
      status: 'authorized',
      numero: 123,
      mensagem_sefaz: nil
    )
  end

  before do
    allow(Nfcom::Emitter).to receive(:new).and_return(emitter)
    travel_to Date.new(2026, 1, 23) # Friday, January 23, 2026
  end

  describe '.call' do
    context 'com datas válidas no mês atual' do
      it 'emite NFCom para faturas no período' do
        allow(emitter).to receive(:emitir).with(fatura_paga.id).and_return(nfcom_record_autorizada)

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:success_count]).to eq(1)
        expect(resultado[:error_count]).to eq(0)
        expect(emitter).to have_received(:emitir).with(fatura_paga.id)
      end

      it 'retorna estrutura de resultado correta' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado).to have_key(:success_count)
        expect(resultado).to have_key(:error_count)
        expect(resultado).to have_key(:faturas_processadas)
        expect(resultado).to have_key(:erros)
      end

      it 'registra informações das faturas processadas' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:faturas_processadas].first).to include(
          fatura_id: fatura_paga.id,
          nfcom_numero: 123,
          status: 'success'
        )
      end
    end

    context 'quando há múltiplas faturas' do
      let(:fatura_paga_2) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: Date.new(2026, 1, 11),
          liquidacao: Date.new(2026, 1, 16),
          valor: 100.00,
          valor_liquidacao: 100.00,
          nossonumero: '10002',
          parcela: 2,
          periodo_inicio: Date.new(2026, 1, 1),
          periodo_fim: Date.new(2026, 1, 31)
        )
      end

      it 'processa todas as faturas' do
        fatura_paga_2 # Force creation
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:success_count]).to eq(2)
        expect(resultado[:faturas_processadas].count).to eq(2)
        expect(emitter).to have_received(:emitir).twice
      end
    end

    context 'quando há erros na emissão' do
      let(:nfcom_record_rejeitada) do
        instance_double(
          NfcomNota,
          status: 'rejected',
          numero: nil,
          mensagem_sefaz: 'Erro na SEFAZ'
        )
      end

      it 'registra erros e continua processando' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_rejeitada)

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:success_count]).to eq(0)
        expect(resultado[:error_count]).to eq(1)
        expect(resultado[:erros].first).to include(
          fatura_id: fatura_paga.id,
          mensagem: 'Erro na SEFAZ'
        )
      end

      it 'captura exceções NotaRejeitada' do
        allow(emitter).to receive(:emitir).and_raise(
          Nfcom::Errors::NotaRejeitada.new('123', 'Documento inválido')
        )

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:error_count]).to eq(1)
        expect(resultado[:erros].first[:mensagem]).to eq('123: Documento inválido')
      end

      it 'captura exceções genéricas' do
        allow(emitter).to receive(:emitir).and_raise(StandardError, 'Erro inesperado')

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:error_count]).to eq(1)
        expect(resultado[:erros].first[:mensagem]).to eq('Erro inesperado')
      end
    end

    context 'com mix de sucessos e erros' do
      let(:fatura_paga_2) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: Date.new(2026, 1, 11),
          liquidacao: Date.new(2026, 1, 16),
          valor: 100.00,
          valor_liquidacao: 100.00,
          nossonumero: '10002',
          parcela: 2,
          periodo_inicio: Date.new(2026, 1, 1),
          periodo_fim: Date.new(2026, 1, 31)
        )
      end

      let(:nfcom_record_rejeitada) do
        instance_double(
          NfcomNota,
          status: 'rejected',
          mensagem_sefaz: 'Erro'
        )
      end

      it 'contabiliza corretamente sucessos e erros' do
        fatura_paga_2 # Force creation
        allow(emitter).to receive(:emitir)
          .with(fatura_paga.id).and_return(nfcom_record_autorizada)
        allow(emitter).to receive(:emitir)
          .with(fatura_paga_2.id).and_return(nfcom_record_rejeitada)

        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 23)
        )

        expect(resultado[:success_count]).to eq(1)
        expect(resultado[:error_count]).to eq(1)
      end
    end

    context 'quando validação de datas' do
      it 'rejeita data_inicio posterior a data_fim' do
        expect do
          described_class.call(
            data_inicio: Date.new(2026, 1, 23),
            data_fim: Date.new(2026, 1, 1)
          )
        end.to raise_error(ArgumentError, 'data_inicio não pode ser posterior a data_fim')
      end

      it 'rejeita data_inicio muito antiga (mais de 5 dias antes do início do mês)' do
        # Current date: 2026-01-23
        # Start of month: 2026-01-01
        # Earliest allowed: 2025-12-27 (5 days before start of month)
        expect do
          described_class.call(
            data_inicio: Date.new(2025, 12, 26), # 6 days before start of month
            data_fim: Date.new(2026, 1, 23)
          )
        end.to raise_error(ArgumentError, /data_inicio .* não pode ser anterior a/)
      end

      it 'aceita data_inicio 5 dias antes do início do mês' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        expect do
          described_class.call(
            data_inicio: Date.new(2025, 12, 27), # Exactly 5 days before Jan 1
            data_fim: Date.new(2026, 1, 23)
          )
        end.not_to raise_error
      end

      it 'rejeita data_fim no futuro' do
        expect do
          described_class.call(
            data_inicio: Date.new(2026, 1, 1),
            data_fim: Date.new(2026, 1, 24) # Tomorrow
          )
        end.to raise_error(ArgumentError, /data_fim .* não pode ser posterior à data atual/)
      end

      it 'aceita data_fim igual à data atual' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        expect do
          described_class.call(
            data_inicio: Date.new(2026, 1, 1),
            data_fim: Date.new(2026, 1, 23) # Today
          )
        end.not_to raise_error
      end

      it 'aceita período parcial no mês atual' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        expect do
          described_class.call(
            data_inicio: Date.new(2026, 1, 15),
            data_fim: Date.new(2026, 1, 20)
          )
        end.not_to raise_error
      end

      it 'aceita período que atravessa a virada do mês (dentro do limite)' do
        allow(emitter).to receive(:emitir).and_return(nfcom_record_autorizada)

        expect do
          described_class.call(
            data_inicio: Date.new(2025, 12, 28), # 4 days before Jan 1
            data_fim: Date.new(2026, 1, 15)
          )
        end.not_to raise_error
      end
    end

    context 'quando não há faturas no período' do
      it 'retorna contadores zerados' do
        resultado = described_class.call(
          data_inicio: Date.new(2026, 1, 1),
          data_fim: Date.new(2026, 1, 5) # Antes da liquidação
        )

        expect(resultado[:success_count]).to eq(0)
        expect(resultado[:error_count]).to eq(0)
        expect(resultado[:faturas_processadas]).to be_empty
        expect(resultado[:erros]).to be_empty
      end
    end
  end
end
