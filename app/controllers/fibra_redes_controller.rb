# frozen_string_literal: true

class FibraRedesController < ApplicationController
  load_and_authorize_resource

  # GET /fibra_redes
  def index
    @q = FibraRede
      .accessible_by(current_ability)
      .ransack(params[:q])

    @q.sorts = %w[ponto_nome nome] if @q.sorts.empty?
    @fibra_redes = @q.result.page(params[:page])
  end

  # GET /fibra_redes/1
  def show
    @params = { rede_id: @fibra_rede }
    @fibra_caixas = @fibra_rede.fibra_caixas.order(:nome)
  end

  # GET /fibra_redes/new
  def new; end

  # GET /fibra_redes/1/edit
  def edit; end

  # POST /fibra_redes
  def create
    if @fibra_rede.save
      redirect_to @fibra_rede, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /fibra_redes/1
  def update
    if @fibra_rede.update(fibra_rede_params)
      redirect_to @fibra_rede, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /fibra_redes/1
  def destroy
    @fibra_rede.destroy
    redirect_to fibra_redes_url, notice: t('.notice')
  end

  private

  def fibra_rede_params
    params.require(:fibra_rede)
      .permit(:nome, :ponto_id, :fibra_cor)
  end
end
