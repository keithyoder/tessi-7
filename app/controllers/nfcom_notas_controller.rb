class NfcomNotasController < ApplicationController
  before_action :set_nfcom_nota, only: [:show]
  load_and_authorize_resource

  def show
    respond_to do |format|
      format.pdf do
        # Check if nota has been authorized
        unless @nfcom_nota.xml_autorizado.present?
          flash[:error] = 'Nota ainda não foi autorizada pela SEFAZ'
          redirect_to fatura_path(@nfcom_nota.fatura) and return
        end

        # Generate PDF
        danfe = Nfcom::Builder::DanfeCom.new(
          @nfcom_nota.xml_autorizado,
          logo_path: Rails.root / 'app' / 'assets' / 'images' / 'logo-cores.svg'
        )
        pdf_content = danfe.gerar

        # Send to browser
        send_data pdf_content,
                  filename: "nfcom_#{@nfcom_nota.numero}_serie_#{@nfcom_nota.serie}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline' # Opens in browser; use 'attachment' to force download
      end
      format.xml do
        if @nfcom_nota.xml_autorizado.present?
          send_data @nfcom_nota.xml_autorizado,
                    filename: "nfcom_#{@nfcom_nota.numero}_serie_#{@nfcom_nota.serie}.xml",
                    type: 'application/xml',
                    disposition: 'attachment'
        else
          flash[:error] = 'Nota ainda não foi autorizada pela SEFAZ'
          redirect_to fatura_path(@nfcom_nota.fatura)
        end
      end

      format.html { redirect_to nfcom_nota_path(@nfcom_nota, format: :pdf) }
    end
  rescue Nfcom::Errors::XmlError => e
    # Handle invalid XML
    flash[:error] = "Erro ao gerar PDF: #{e.message}"
    redirect_to fatura_path(@nfcom_nota.fatura)
  rescue StandardError => e
    # Handle other errors
    Rails.logger.error("Erro ao gerar DANFE-COM: #{e.message}\n#{e.backtrace.join("\n")}")
    flash[:error] = 'Erro ao gerar PDF da nota'
    redirect_to fatura_path(@nfcom_nota.fatura)
  end

  private

  def set_nfcom_nota
    @nfcom_nota = NfcomNota.find(params[:id])
  end
end
