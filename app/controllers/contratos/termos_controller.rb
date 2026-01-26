# frozen_string_literal: true

module Contratos
  class TermosController < BaseController
    load_and_authorize_resource class: 'ContratoTermo', parent: false

    # GET /contratos/:contrato_id/termo
    # Just shows or downloads the PDF
    def show
      pdf = Contratos::TermoService.new(@contrato).gerar_pdf
      send_data pdf,
                filename: "termo_#{@contrato.id}.pdf",
                type: 'application/pdf',
                disposition: 'inline' # or 'attachment' to force download
    end

    # POST /contratos/:contrato_id/termo
    # Sends to Autentique for signature
    def create
      authorize! :assinar, @contrato

      Contratos::TermoService.new(@contrato).enviar_para_assinatura
      redirect_to @contrato, notice: t('.notice')
    rescue Contratos::TermoService::Error => e
      redirect_to @contrato, alert: "Erro ao enviar termo para assinatura: #{e.message}"
    end

    private

    def set_contrato
      @contrato = Contrato.find(params[:contrato_id])
    end
  end
end
