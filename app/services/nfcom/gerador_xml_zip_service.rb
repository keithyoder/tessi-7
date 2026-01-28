# frozen_string_literal: true

module Nfcom
  class GeradorXmlZipService
    def initialize(notas)
      @notas = notas
    end

    def generate
      Zip::OutputStream.write_buffer do |zip|
        @notas.each do |nota|
          next if nota.xml_autorizado.blank?

          zip.put_next_entry(filename_for(nota))
          zip.write nota.xml_autorizado
        end
      end
    end

    private

    def filename_for(nota)
      "NFCom_#{nota.serie}_#{nota.numero.to_s.rjust(9, '0')}_#{nota.chave_acesso}.xml"
    end
  end
end
