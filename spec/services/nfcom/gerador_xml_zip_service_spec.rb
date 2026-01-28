# frozen_string_literal: true

require 'rails_helper'
require 'zip'

RSpec.describe Nfcom::GeradorXmlZipService do
  subject(:service) { described_class.new(notas) }

  let(:xml_content) { '<xml>conteudo</xml>' }

  let(:nota_com_xml) do
    instance_double(
      NfcomNota,
      xml_autorizado: xml_content,
      serie: '1',
      numero: 123,
      chave_acesso: 'ABC123'
    )
  end

  let(:nota_sem_xml) do
    instance_double(
      NfcomNota,
      xml_autorizado: nil
    )
  end

  let(:notas) { [nota_com_xml, nota_sem_xml] }

  describe '#generate' do
    it 'generates a zip with only authorized XML files' do
      buffer = service.generate

      entries = []

      Zip::InputStream.open(StringIO.new(buffer.string)) do |zip|
        while (entry = zip.get_next_entry)
          entries << {
            name: entry.name,
            content: entry.get_input_stream.read
          }
        end
      end

      expect(entries.size).to eq(1)

      expect(entries.first[:name]).to eq(
        'NFCom_1_000000123_ABC123.xml'
      )

      expect(entries.first[:content]).to eq(xml_content)
    end

    it 'returns a Zip::OutputStream buffer' do
      result = service.generate

      expect(result).to be_a(StringIO)
    end
  end
end
