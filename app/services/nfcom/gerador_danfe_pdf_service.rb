# frozen_string_literal: true

module Nfcom
  class GeradorDanfePdfService
    def initialize(nota)
      @nota = nota
    end

    def generate
      raise Nfcom::Errors::XmlError, 'XML não autorizado' if @nota.xml_autorizado.blank?

      Nfcom::Builder::DanfeCom.new(
        @nota.xml_autorizado,
        logo_path: Rails.root / 'app/assets/images/logo-cores.svg'
      ).gerar
    end
  end
end
