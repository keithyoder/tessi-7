# frozen_string_literal: true

class ClassificacoesController < ApplicationController
  before_action :set_classificacao, only: %i[edit update destroy]
  authorize_resource

  # GET /classificacoes or /classificacoes.json
  def index # rubocop:disable Metrics/AbcSize
    @q = Classificacao.accessible_by(current_ability).ransack(params[:q])
    @q.sorts = ['tipo asc', 'nome asc'] if @q.sorts.empty?
    @search_params = @q.conditions.to_h { |c| [c.attributes.first, c.values.first] }

    respond_to do |format|
      format.html { @pagy, @classificacoes = pagy(@q.result, limit: 12) }
      format.json do
        classificacoes = Classificacao.accessible_by(current_ability)
        classificacoes = classificacoes.where(tipo: params[:tipo]) if params[:tipo].present?
        render json: classificacoes.order(:nome).select(:id, :nome, :tipo)
      end
    end
  end

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
        format.html { redirect_to classificacoes_path, notice: t('.notice') }
        format.json { render json: @classificacao, status: :created }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @classificacao.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /classificacoes/1 or /classificacoes/1.json
  def update
    respond_to do |format|
      if @classificacao.update(classificacao_params)
        format.html { redirect_to classificacoes_path, notice: t('.notice') }
        format.json { render json: @classificacao, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @classificacao.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /classificacoes/1 or /classificacoes/1.json
  def destroy
    @classificacao.destroy
    respond_to do |format|
      format.html { redirect_to classificacoes_url, notice: t('.notice') }
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
    params.require(:classificacao).permit(:tipo, :nome, :sla_dias)
  end
end
