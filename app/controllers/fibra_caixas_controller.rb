# frozen_string_literal: true

class FibraCaixasController < ApplicationController
  include ConexoesHelper

  load_and_authorize_resource

  # GET /fibra_caixas
  def index
    @fibra_caixas = FibraCaixa.accessible_by(current_ability)
  end

  # GET /fibra_caixas/1
  def show
    @q = @fibra_caixa.conexoes.ransack(params[:q])
    @q.sorts = 'ip' if @q.sorts.empty?

    @params = conexoes_params(params)
    @conexoes = @q.result.page(params[:conexoes_page])
  end

  # GET /fibra_caixas/new
  def new; end

  # GET /fibra_caixas/1/edit
  def edit; end

  # POST /fibra_caixas
  def create
    if @fibra_caixa.save
      redirect_to @fibra_caixa, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /fibra_caixas/1
  def update
    if @fibra_caixa.update(fibra_caixa_params)
      redirect_to @fibra_caixa, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /fibra_caixas/1
  def destroy
    @fibra_caixa.destroy
    redirect_to fibra_caixas_url, notice: t('.notice')
  end

  private

  def fibra_caixa_params
    params.require(:fibra_caixa).permit(
      :nome,
      :fibra_rede_id,
      :capacidade,
      :poste,
      :logradouro_id,
      :latitude,
      :longitude,
      :fibra_cor
    )
  end
end
