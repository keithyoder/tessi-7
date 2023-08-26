# frozen_string_literal: true

class EstadosController < ApplicationController
  load_and_authorize_resource
  before_action :set_estado, only: %i[show edit update destroy]

  # GET /estados
  # GET /estados.json
  def index
    @q = Estado.ransack(params[:q])
    @estados = @q.result(order: :nome).page params[:page]
    respond_to do |format|
      format.html
      format.csv { send_data @estados.except(:limit, :offset).to_csv, filename: "estados-#{Date.today}.csv" }
    end
  end

  # GET /estados/1
  # GET /estados/1.json
  def show
    @estado = Estado.find(params[:id])
    @q = @estado.cidades.ransack(params[:q])
    @q.sorts = 'nome'
    @cidades = @q.result.page params[:page]
  end

  # GET /estados/new
  def new
    @estado = Estado.new
  end

  # GET /estados/1/edit
  def edit; end

  # PATCH/PUT /estados/1
  # PATCH/PUT /estados/1.json
  def update
    if @estado.update(estado_params)
      redirect_to @estado, notice: 'Estado atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_estado
    @estado = Estado.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def estado_params
    params.require(:estado).permit(:sigla, :nome, :ibge)
  end
end
