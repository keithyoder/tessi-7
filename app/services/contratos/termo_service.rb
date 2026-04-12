# frozen_string_literal: true

module Contratos
  class TermoService
    class Error < StandardError; end

    def initialize(contrato)
      @contrato = contrato
    end

    def enviar_para_assinatura
      pdf = gerar_pdf

      client.documents.create(
        file: { io: pdf, name: "termo_#{@contrato.id}.pdf", mime_type: 'application/pdf' },
        document: {
          name: "Termo #{@contrato.id}",
          footer: 'BOTTOM'
        },
        signers: [
          {
            phone: "+55#{@contrato.pessoa.telefone1.gsub(/[^0-9]/, '')}",
            delivery_method: 'DELIVERY_METHOD_WHATSAPP',
            action: 'SIGN',
            configs: { cpf: CPF.new(@contrato.pessoa.cpf).stripped }
          }
        ]
      )
    rescue StandardError => e
      raise Error, e.message
    end

    def gerar_pdf
      pdf_content = WickedPdf.new.pdf_from_string(
        ContratosController.render(
          template: 'contratos/termo',
          assigns: { contrato: @contrato },
          layout: false,
          formats: [:html]
        ),
        encoding: 'UTF-8',
        zoom: 1.2,
        margin: { top: 15, bottom: 18, left: 15, right: 15 },
        page_size: 'A4'
      )

      io = StringIO.new(pdf_content)
      io.set_encoding('BINARY')
      io
    end

    private

    def client
      @client ||= Autentique.client
    end
  end
end
