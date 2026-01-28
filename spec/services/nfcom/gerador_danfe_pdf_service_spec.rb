# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Nfcom::GeradorDanfePdfService do
  subject(:service) { described_class.new(nota) }

  let(:xml_content) { '<xml>conteudo</xml>' }
  let(:pdf_content) { '%PDF-1.4 fake pdf' }

  let(:nota) do
    instance_double(
      NfcomNota,
      xml_autorizado: xml_content
    )
  end

  let(:danfe_builder) do
    instance_double(
      Nfcom::Builder::DanfeCom,
      gerar: pdf_content
    )
  end

  describe '#generate' do
    context 'when XML is authorized' do
      before do
        allow(Nfcom::Builder::DanfeCom)
          .to receive(:new)
          .with(
            xml_content,
            logo_path: Rails.root / 'app/assets/images/logo-cores.svg'
          )
          .and_return(danfe_builder)
      end

      it 'builds the DANFE with the correct parameters' do
        service.generate

        expect(Nfcom::Builder::DanfeCom).to have_received(:new)
      end

      it 'calls gerar on the DANFE builder' do
        result = service.generate

        expect(result).to eq(pdf_content)
        expect(danfe_builder).to have_received(:gerar)
      end
    end

    context 'when XML is not authorized' do
      let(:nota) do
        instance_double(
          NfcomNota,
          xml_autorizado: nil
        )
      end

      it 'raises an XmlError' do
        expect { service.generate }
          .to raise_error(Nfcom::Errors::XmlError, 'XML não autorizado')
      end
    end
  end
end
