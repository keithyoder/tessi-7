# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contratos::TermoService, type: :service do
  let(:contrato) { create(:contrato, documentos: []) }
  let(:service) { described_class.new(contrato) }

  let(:documents_proxy) { instance_spy(Autentique::Documents) }

  let(:document_double) do
    instance_double(
      Autentique::Document,
      id: 'doc-123',
      name: 'Contrato 1',
      created_at: Time.zone.now
    )
  end

  let(:client) { instance_double(Autentique::Client, documents: documents_proxy) }

  before do
    stub_const('Autentique::Documents', Class.new)
    stub_const('Autentique::Document', Class.new)
    stub_const('Autentique::Client', Class.new)
    allow(service).to receive(:gerar_pdf).and_return('%PDF-FAKE')
    allow(Autentique).to receive(:client).and_return(client)
    allow(documents_proxy).to receive(:create).and_return(document_double)
  end

  describe '#enviar_para_assinatura' do
    it 'calls the Autentique client to send the PDF' do
      service.enviar_para_assinatura

      expect(documents_proxy).to have_received(:create)
    end

    it 'saves the document info in contrato.documentos' do
      expect do
        service.enviar_para_assinatura
      end.to change { contrato.reload.documentos.size }.by(1)

      doc = contrato.reload.documentos.last
      expect(doc['id']).to eq('doc-123')
      expect(doc['nome']).to eq('Contrato 1')
    end

    context 'when the client raises an error' do
      before do
        allow(documents_proxy).to receive(:create)
          .and_raise(StandardError, 'API failure')
      end

      it 'raises TermoService::Error' do
        expect do
          service.enviar_para_assinatura
        end.to raise_error(
          Contratos::TermoService::Error,
          'API failure'
        )
      end
    end
  end
end
