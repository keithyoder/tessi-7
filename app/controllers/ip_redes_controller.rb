# frozen_string_literal: true

class IpRedesController < ApplicationController
  load_and_authorize_resource

  # GET /ip_redes
  def index
    @q = IpRede
      .accessible_by(current_ability)
      .ransack(params[:q])

    @q.sorts = ['rede'] if @q.sorts.empty?
    @ip_redes = @q.result.page(params[:page])
  end

  # GET /ip_redes/1
  def show; end

  # GET /ip_redes/new
  def new; end

  # GET /ip_redes/1/edit
  def edit; end

  # POST /ip_redes
  def create
    if @ip_rede.save
      redirect_to @ip_rede, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /ip_redes/1
  def update
    if @ip_rede.update(ip_rede_params)
      redirect_to @ip_rede, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /ip_redes/1
  def destroy
    @ip_rede.destroy
    redirect_to ip_redes_url, notice: t('.notice')
  end

  private

  def ip_rede_params
    params.require(:ip_rede).permit(:rede, :ponto_id, :subnet)
  end
end
