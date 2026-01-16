class NfcomNotasController < ApplicationController
  before_action :set_nfcom_nota, only: [:show_pdf]

  def show
    pdf = NfcomPdf.new(@nfcom_nota).render

    respond_to do |format|
      format.pdf do
        send_data pdf,
                  filename: "NFCom-#{@nfcom_nota.numero}-#{@nfcom_nota.serie}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  private

  def set_nfcom_nota
    @nfcom_nota = NfcomNota.find(params[:id])
  end
end
