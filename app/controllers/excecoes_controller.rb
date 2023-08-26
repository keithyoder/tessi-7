# frozen_string_literal: true

class ExcecoesController < ApplicationController
  load_and_authorize_resource
  before_action :set_excecao, only: %i[show edit update destroy]
  before_action :set_contratos, only: %i[new edit]

  # GET /excecoes
  # GET /excecoes.json
  def index
    @q = Excecao.ransack(params[:q])
    @excecoes = @q.result(order: :valido_ate).page params[:page]
    respond_to do |format|
      format.html
      format.csv do
        send_data @excecoes.except(:limit, :offset).to_csv, filename: "excecoes-#{Date.today}.csv"
      end
    end
  end

  # GET /excecoes/1
  # GET /excecoes/1.json
  def show; end

  # GET /excecoes/new
  def new
    @excecao = Excecao.new
  end

  # GET /excecoes/1/edit
  def edit; end

  # POST /excecoes
  # POST /excecoes.json
  def create
    @excecao = Excecao.new(excecao_params)

    respond_to do |format|
      if @excecao.save
        format.html { redirect_to @excecao, notice: 'Exceção criada com sucesso.' }
        format.json { render :show, status: :created, location: @excecao }
      else
        format.html { render :new }
        format.json { render json: @excecao.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /excecoes/1
  # PATCH/PUT /excecoes/1.json
  def update
    respond_to do |format|
      if @excecao.update(excecao_params)
        format.html { redirect_to @excecao, notice: 'Exceção atualizada com sucesso.' }
        format.json { render :show, status: :ok, location: @excecao }
      else
        format.html { render :edit }
        format.json { render json: @excecao.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /excecoes/1
  # DELETE /excecoes/1.json
  def destroy
    @excecao.destroy
    respond_to do |format|
      format.html { redirect_to excecoes_url, notice: 'Excecao was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_excecao
    @excecao = Excecao.find(params[:id])
  end

  def set_contratos
    @contratos = Contrato.ativos.eager_load(:pessoa).order('pessoas.nome')
  end

  # Only allow a list of trusted parameters through.
  def excecao_params
    params.require(:excecao).permit(:contrato_id, :valido_ate, :tipo, :usuario)
  end
end
