# frozen_string_literal: true

class EquipamentosController < ApplicationController
  load_and_authorize_resource

  def index
    @q = Equipamento
      .accessible_by(current_ability)
      .order(:fabricante, :modelo)
      .ransack(params[:q])

    @equipamentos = @q.result.page(params[:page])
  end

  def show; end
  def new; end
  def edit; end

  def create
    if @equipamento.save
      redirect_to @equipamento, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @equipamento.update(equipamento_params)
      redirect_to @equipamento, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @equipamento.destroy
    redirect_to equipamentos_url, notice: t('.notice')
  end

  private

  def equipamento_params
    params.require(:equipamento)
      .permit(:fabricante, :modelo, :tipo, :imagem)
  end
end
