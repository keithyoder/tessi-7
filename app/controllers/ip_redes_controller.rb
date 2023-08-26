# frozen_string_literal: true

class IpRedesController < ApplicationController
  before_action :set_ip_rede, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /ip_redes
  # GET /ip_redes.json
  def index
    @q = IpRede.ransack(params[:q])
    @q.sorts = ['rede']
    @ip_redes = @q.result.page params[:page]
  end

  # GET /ip_redes/1
  # GET /ip_redes/1.json
  def show; end

  # GET /ip_redes/new
  def new
    @ip_rede = IpRede.new
  end

  # GET /ip_redes/1/edit
  def edit; end

  # POST /ip_redes
  # POST /ip_redes.json
  def create
    @ip_rede = IpRede.new(ip_rede_params)

    respond_to do |format|
      if @ip_rede.save
        format.html { redirect_to @ip_rede, notice: 'Rede IP criada com sucesso.' }
        format.json { render :show, status: :created, location: @ip_rede }
      else
        format.html { render :new }
        format.json { render json: @ip_rede.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ip_redes/1
  # PATCH/PUT /ip_redes/1.json
  def update
    respond_to do |format|
      if @ip_rede.update(ip_rede_params)
        format.html { redirect_to @ip_rede, notice: 'Rede IP atualizada com sucesso.' }
        format.json { render :show, status: :ok, location: @ip_rede }
      else
        format.html { render :edit }
        format.json { render json: @ip_rede.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_redes/1
  # DELETE /ip_redes/1.json
  def destroy
    @ip_rede.destroy
    respond_to do |format|
      format.html { redirect_to ip_redes_url, notice: 'Ip rede was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ip_rede
    @ip_rede = IpRede.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def ip_rede_params
    params.require(:ip_rede).permit(:rede, :ponto_id, :subnet)
  end
end
