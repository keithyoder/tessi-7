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
    send_data(
      build_competencia_zip(params[:mes]),
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

  def build_competencia_zip(mes)
    cadastro, mestre, itens = build_nf21_streams(mes)
    zipio = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry(nome_arquivo(mes, 'D'))
      zio.write cadastro.read
      zio.put_next_entry(nome_arquivo(mes, 'M'))
      zio.write mestre.read
      zio.put_next_entry(nome_arquivo(mes, 'I'))
      zio.write itens.read
    end
    zipio.rewind
    zipio.sysread
  end

  def build_nf21_streams(mes)
    cadastro = StringIO.new.tap { |s| s.set_encoding('iso-8859-14') }
    mestre = StringIO.new.tap { |s| s.set_encoding('iso-8859-14') }
    itens = StringIO.new.tap { |s| s.set_encoding('iso-8859-14') }
    Nf21.competencia(mes).order(:numero).each do |nf|
      cadastro << nf.cadastro
      mestre << nf.mestre
      nf.nf21_itens.each { |item| itens << item.item }
    end
    [cadastro.tap(&:rewind), mestre.tap(&:rewind), itens.tap(&:rewind)]
  end

  def nome_arquivo(mes, letra)
    "PE#{Setting.cnpj}21U  #{mes[2..3]}#{mes[5..6]}N01#{letra}.011"
  end
end
