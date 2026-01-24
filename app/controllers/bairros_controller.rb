# frozen_string_literal: true

class BairrosController < ApplicationController
  include ConexoesHelper

  load_and_authorize_resource

  # GET /bairros
  def index
    @q = Bairro.ransack(params[:q])
    @bairros = @q.result.order(:nome).page(params[:bairros_page])
    @params = {}

    respond_to do |format|
      format.html
      format.csv { send_data export_csv, filename: csv_filename }
    end
  end

  # GET /bairros/1
  def show
    @q = @bairro.logradouros.ransack(params[:q])
    @logradouros = @q.result.order(:nome).page(params[:logradouros_page])

    @conexao_q = @bairro.conexoes.ransack(params[:conexao_q])
    @conexoes = @conexao_q.result.order(:ip).page(params[:conexoes_page])

    @params = conexoes_params(params)
  end

  # GET /bairros/new
  def new
    # @bairro is already initialized by load_and_authorize_resource
    # Preload associations if needed
    @bairro.cidade ||= Cidade.new
  end

  # GET /bairros/1/edit
  def edit
    # @bairro is already loaded by load_and_authorize_resource
  end

  # POST /bairros
  def create
    if @bairro.save
      redirect_to @bairro, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /bairros/1
  def update
    if @bairro.update(bairro_params)
      redirect_to @bairro, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /bairros/1
  def destroy
    @bairro.destroy
    redirect_to bairros_url, notice: t('.notice')
  end

  private

  def bairro_params
    params.require(:bairro).permit(:nome, :cidade_id, :latitude, :longitude)
  end

  def export_csv
    @bairros.except(:limit, :offset).to_csv
  end

  def csv_filename
    "bairros-#{Time.zone.today}.csv"
  end
end
