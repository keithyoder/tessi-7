# frozen_string_literal: true

class FibraCaixasController < ApplicationController
  include ConexoesHelper

  load_and_authorize_resource
  before_action :set_fibra_caixa, only: %i[show edit update destroy]

  # GET /fibra_caixas
  # GET /fibra_caixas.json
  def index
    @fibra_caixas = FibraCaixa.all
  end

  # GET /fibra_caixas/1
  # GET /fibra_caixas/1.json
  def show
    @q = @fibra_caixa.conexoes.ransack(params[:q])
    @q.sorts = 'ip'
    @params = conexoes_params(params)
    @conexoes = @q.result.page params[:conexoes_page]
  end

  # GET /fibra_caixas/new
  def new
    @fibra_caixa = FibraCaixa.new
  end

  # GET /fibra_caixas/1/edit
  def edit; end

  # POST /fibra_caixas
  # POST /fibra_caixas.json
  def create
    @fibra_caixa = FibraCaixa.new(fibra_caixa_params)

    respond_to do |format|
      if @fibra_caixa.save
        format.html { redirect_to @fibra_caixa, notice: 'Fibra caixa was successfully created.' }
        format.json { render :show, status: :created, location: @fibra_caixa }
      else
        format.html { render :new }
        format.json { render json: @fibra_caixa.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fibra_caixas/1
  # PATCH/PUT /fibra_caixas/1.json
  def update
    respond_to do |format|
      if @fibra_caixa.update(fibra_caixa_params)
        format.html { redirect_to @fibra_caixa, notice: 'Fibra caixa was successfully updated.' }
        format.json { render :show, status: :ok, location: @fibra_caixa }
      else
        format.html { render :edit }
        format.json { render json: @fibra_caixa.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fibra_caixas/1
  # DELETE /fibra_caixas/1.json
  def destroy
    @fibra_caixa.destroy
    respond_to do |format|
      format.html { redirect_to fibra_caixas_url, notice: 'Fibra caixa was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_fibra_caixa
    @fibra_caixa = FibraCaixa.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def fibra_caixa_params
    params.require(:fibra_caixa).permit(:nome, :fibra_rede_id, :capacidade, :poste, :logradouro_id,
                                        :latitude, :longitude, :fibra_cor)
  end
end
