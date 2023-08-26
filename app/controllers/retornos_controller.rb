# frozen_string_literal: true

class RetornosController < ApplicationController
  load_and_authorize_resource
  before_action :set_retorno, only: %i[show edit update destroy]

  # GET /retornos
  # GET /retornos.json
  def index
    @q = Retorno.joins(:pagamento_perfil).where.not(pagamento_perfis: {banco: 364}).ransack(params[:q])
    @q.sorts = 'data desc'
    @retornos = @q.result.page params[:page]
  end

  # GET /retornos/1
  # GET /retornos/1.json
  def show
    @faturas = Fatura.where(pagamento_perfil: @retorno.pagamento_perfil)
    @linhas = @retorno.carregar_arquivo
  end

  # GET /retornos/new
  def new
    @retorno = Retorno.new
  end

  # GET /retornos/1/edit
  def edit; end

  # POST /retornos
  # POST /retornos.json
  def create
    @retorno = Retorno.new(retorno_params)

    respond_to do |format|
      if @retorno.save
        format.html { redirect_to @retorno, notice: 'Retorno was successfully created.' }
        format.json { render :show, status: :created, location: @retorno }
      else
        format.html { render :new }
        format.json { render json: @retorno.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /retornos/1
  # PATCH/PUT /retornos/1.json
  def update
    @retorno.processar
    respond_to do |format|
      format.html { redirect_to @retorno, notice: 'Retorno was successfully updated.' }
      format.json { render :show, status: :ok, location: @retorno }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to @retorno, notice: e.message }
      format.json { render :show, status: :ok, location: @retorno }
    end
  end

  # DELETE /retornos/1
  # DELETE /retornos/1.json
  def destroy
    @retorno.destroy
    respond_to do |format|
      format.html { redirect_to retornos_url, notice: 'Retorno was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_retorno
    @retorno = Retorno.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def retorno_params
    params.require(:retorno).permit(:pagamento_perfil_id, :data, :sequencia, :arquivo)
  end
end
