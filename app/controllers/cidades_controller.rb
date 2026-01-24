# frozen_string_literal: true

class CidadesController < ApplicationController
  load_and_authorize_resource

  # GET /cidades
  def index
    @q = Cidade.ransack(params[:q])
    @cidades = @q.result.order(:nome).page(params[:page])

    respond_to do |format|
      format.html
      format.csv { send_data export_cidades_csv, filename: csv_filename('cidades') }
    end
  end

  # GET /cidades/sici
  def sici
    @sici = Cidade.assinantes.order(:nome)
    @conexoes = Conexao.ativo

    respond_to do |format|
      format.html
      format.csv { send_data export_sici_csv, filename: csv_filename('sici') }
    end
  end

  # GET /cidades/1
  def show
    @q = @cidade.bairros.ransack(params[:q])
    @bairros = @q.result.order(:nome).page(params[:page])
    @logradouros = @cidade.logradouros.page(params[:page])
    @params = params.permit(:tab)
  end

  # GET /cidades/new
  def new
    # @cidade is already initialized by load_and_authorize_resource
  end

  # GET /cidades/1/edit
  def edit
    # @cidade is already loaded by load_and_authorize_resource
  end

  # POST /cidades
  def create
    if @cidade.save
      redirect_to cidades_path, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /cidades/1
  def update
    if @cidade.update(cidade_params)
      redirect_to cidades_path, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /cidades/1
  def destroy
    @cidade.destroy
    redirect_to cidades_url, notice: t('.notice')
  end

  private

  def cidade_params
    params.require(:cidade).permit(:nome, :estado_id, :ibge)
  end

  def export_cidades_csv
    @cidades.except(:limit, :offset).to_csv
  end

  def export_sici_csv
    @sici.except(:limit, :offset).to_csv
  end

  def csv_filename(prefix)
    "#{prefix}-#{Time.zone.today}.csv"
  end
end
