class NfcomNotasController < ApplicationController
  before_action :set_nfcom_nota, only: [:show]
  load_and_authorize_resource

  def show
    respond_to do |format|
      format.pdf
      format.html { redirect_to nfcom_nota_path(@nfcom_nota, format: :pdf) }
    end
  end

  private

  def set_nfcom_nota
    @nfcom_nota = NfcomNota.find(params[:id])
  end
end
