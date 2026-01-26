# frozen_string_literal: true

module Contratos
  class TermoService
    class Error < StandardError; end

    def initialize(contrato)
      @contrato = contrato
    end

    def enviar_para_assinatura
      pdf = gerar_pdf

      documento = client.documents.create(
        file: pdf,
        document: {
          name: "Contrato #{@contrato.id}",
          message: 'Por favor, assine este contrato'
        },
        signers: [
          {
            email: @contrato.pessoa.email,
            action: 'SIGN',
            configs: { cpf: @contrato.pessoa.cpf }
          }
        ]
      )

      @contrato.update!(
        documentos: Array(@contrato.documentos) + [{
          'id' => documento.id,
          'nome' => documento.name,
          'data' => documento.created_at
        }]
      )

      documento
    rescue StandardError => e
      raise Error, e.message
    end

    def gerar_pdf
      WickedPdf.new.pdf_from_string(
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
    end

    private

    def client
      @client ||= Autentique.client
    end
  end
end
