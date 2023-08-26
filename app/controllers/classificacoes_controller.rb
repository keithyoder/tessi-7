# frozen_string_literal: true

class ClassificacoesController < ApplicationController
  before_action :set_classificacao, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /classificacoes or /classificacoes.json
  def index
    classificacao = Classificacao
    classificacao = classificacao.where(tipo: params[:tipo]) if params.key?(:tipo)
    @q = classificacao.ransack(params[:q])
    @q.sorts = 'tipo_nome'
    @classificacoes = @q.result.page params[:page]
  end

  # GET /classificacoes/1 or /classificacoes/1.json
  def show; end

  # GET /classificacoes/new
  def new
    @classificacao = Classificacao.new
  end

  # GET /classificacoes/1/edit
  def edit; end

  # POST /classificacoes or /classificacoes.json
  def create
    @classificacao = Classificacao.new(classificacao_params)

    respond_to do |format|
      if @classificacao.save
        format.html { redirect_to @classificacao, notice: 'Classificacao was successfully created.' }
        format.json { render :show, status: :created, location: @classificacao }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @classificacao.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /classificacoes/1 or /classificacoes/1.json
  def update
    respond_to do |format|
      if @classificacao.update(classificacao_params)
        format.html { redirect_to @classificacao, notice: 'Classificação criada com sucesso.' }
        format.json { render :show, status: :ok, location: @classificacoes }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @classificacao.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /classificacoes/1 or /classificacoes/1.json
  def destroy
    @classificacao.destroy
    respond_to do |format|
      format.html { redirect_to classificacoes_url, notice: 'Classificacao was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_classificacao
    @classificacao = Classificacao.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def classificacao_params
    params.require(:classificacao).permit(:tipo, :nome)
  end
end
