# frozen_string_literal: true

class CidadesController < ApplicationController
  before_action :set_cidade, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /cidades
  # GET /cidades.json
  def index
    @q = Cidade.ransack(params[:q])
    @cidades = @q.result(order: :nome).page params[:page]
    respond_to do |format|
      format.html
      format.csv { send_data @cidades.except(:limit, :offset).to_csv, filename: "cidades-#{Date.today}.csv" }
    end
  end

  def sici
    @sici = Cidade.assinantes.order(:nome)
    @conexoes = Conexao.ativo
    respond_to do |format|
      format.html
      format.csv { send_data @sici.except(:limit, :offset).to_csv, filename: "sici-#{Date.today}.csv" }
    end
  end

  # GET /cidades/1
  # GET /cidades/1.json
  def show
    @cidade = Cidade.find(params[:id])
    @q = @cidade.bairros.ransack(params[:q])
    @q.sorts = 'nome'
    @bairros = @q.result.page params[:page]
    @logradouros = @cidade.logradouros.page params[:page]
    @params = params.permit(:tab)
  end

  # GET /cidades/new
  def new
    @cidade = Cidade.new
  end

  # GET /cidades/1/edit
  def edit; end

  # POST /cidades
  # POST /cidades.json
  def create
    @cidade = Cidade.new(cidade_params)

    respond_to do |format|
      if @cidade.save
        format.html { redirect_to cidades_path, notice: 'Cidade was successfully created.' }
        format.json { render :show, status: :created, location: @cidade }
      else
        format.html { render :new }
        format.json { render json: @cidade.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cidades/1
  # PATCH/PUT /cidades/1.json
  def update
    respond_to do |format|
      if @cidade.update(cidade_params)
        format.html { redirect_to cidades_path, notice: 'Cidade was successfully updated.' }
        format.json { render :show, status: :ok, location: @cidade }
      else
        format.html { render :edit }
        format.json { render json: @cidade.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cidades/1
  # DELETE /cidades/1.json
  def destroy
    @cidade.destroy
    respond_to do |format|
      format.html { redirect_to cidades_url, notice: 'Cidade was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_cidade
    @cidade = Cidade.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cidade_params
    params.require(:cidade).permit(:nome, :estado_id, :ibge)
  end
end
