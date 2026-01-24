# frozen_string_literal: true

class EstadosController < ApplicationController
  load_and_authorize_resource

  # GET /estados
  def index
    @q = Estado.ransack(params[:q])
    @estados = @q.result.order(:nome).page(params[:page])

    respond_to do |format|
      format.html
      format.csv { send_data export_csv, filename: csv_filename }
    end
  end

  # GET /estados/1
  def show
    # @estado is already loaded by load_and_authorize_resource
    @q = @estado.cidades.ransack(params[:q])
    @cidades = @q.result.order(:nome).page(params[:page])
  end

  # GET /estados/new
  def new
    # @estado is already initialized by load_and_authorize_resource
  end

  # GET /estados/1/edit
  def edit
    # @estado is already loaded by load_and_authorize_resource
  end

  # PATCH/PUT /estados/1
  def update
    if @estado.update(estado_params)
      redirect_to @estado, notice: t('estados.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def estado_params
    params.require(:estado).permit(:sigla, :nome, :ibge)
  end

  def export_csv
    @estados.except(:limit, :offset).to_csv
  end

  def csv_filename
    "estados-#{Time.zone.today}.csv"
  end
end
