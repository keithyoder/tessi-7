# frozen_string_literal: true

require 'stringio'

class Nf21sController < ApplicationController
  before_action :set_nf21, only: %i[show]
  load_and_authorize_resource

  # GET /nf21s/1
  # GET /nf21s/1.json
  def show
    respond_to do |format|
      format.pdf
      format.html { redirect_to nf21_path(@nf21, format: :pdf) }
    end
  end

  def competencia
    cadastro = StringIO.new
    mestre = StringIO.new
    itens = StringIO.new
    cadastro.set_encoding('iso-8859-14')
    mestre.set_encoding('iso-8859-14')
    itens.set_encoding('iso-8859-14')
    Nf21.competencia(params[:mes]).order(:numero).each do |nf|
      cadastro << nf.cadastro
      mestre << nf.mestre
      nf.nf21_itens.each do |item|
        itens << item.item
      end
    end
    cadastro.rewind
    mestre.rewind
    itens.rewind
    zipio = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry(nome_arquivo(params[:mes], 'D'))
      zio.write cadastro.read
      zio.put_next_entry(nome_arquivo(params[:mes], 'M'))
      zio.write mestre.read
      zio.put_next_entry(nome_arquivo(params[:mes], 'I'))
      zio.write itens.read
    end
    zipio.rewind
    send_data(
      zipio.sysread,
      content_type: 'application/zip',
      disposition: 'attachment',
      filename: "competencia-#{params[:mes]}.zip"
    )
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_nf21
    @nf21 = Nf21.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def nf21_params
    params.require(:nf21).permit(:emissao, :numero, :valor, :cadastro, :mestre)
  end

  def nome_arquivo(mes, letra)
    "PE#{Setting.cnpj}21U  #{mes[2..3]}#{mes[5..6]}N01#{letra}.011"
  end
end
