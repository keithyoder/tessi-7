# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RenovarContratosJob, type: :job do
  describe '#perform' do
    let(:resultado_mock) do
      Contratos::RenovacaoEmLoteService::Resultado.new(
        sucesso: ['João Silva', 'Maria Santos'],
        ignorados: ['Pedro Costa'],
        erros: { 'Ana Lima' => 'Erro ao gerar faturas' }
      )
    end

    let(:service) { instance_double(Contratos::RenovacaoEmLoteService, call: resultado_mock) }

    before do
      allow(Contratos::RenovacaoEmLoteService).to receive(:new).and_return(service)
    end

    it 'chama o serviço de renovação em lote' do
      # Suppress output for this test
      allow(service).to receive(:puts)
      allow($stdout).to receive(:puts)

      described_class.perform_now(pagamento_perfil_id: 1, meses_por_fatura: 3)

      expect(Contratos::RenovacaoEmLoteService).to have_received(:new).with(
        pagamento_perfil_id: 1,
        meses_por_fatura: 3
      )
      expect(service).to have_received(:call)
    end

    it 'imprime relatório com contratos renovados', :aggregate_failures do
      output = capture_stdout do
        described_class.perform_now(pagamento_perfil_id: 1)
      end

      expect(output).to include('João Silva')
      expect(output).to include('Maria Santos')
      expect(output).to include('Pedro Costa')
      expect(output).to include('Ana Lima')
      expect(output).to include('Contratos renovados (2)')
      expect(output).to include('Contratos ignorados (1)')
      expect(output).to include('Erros (1)')
    end

    it 'usa valores padrão para parâmetros opcionais' do
      # Suppress output for this test
      allow($stdout).to receive(:puts)

      described_class.perform_now

      expect(Contratos::RenovacaoEmLoteService).to have_received(:new).with(
        pagamento_perfil_id: 1,
        meses_por_fatura: 1
      )
    end
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
