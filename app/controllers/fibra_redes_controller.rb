# frozen_string_literal: true

class FibraRedesController < ApplicationController
  load_and_authorize_resource
  before_action :set_fibra_rede, only: %i[show edit update destroy]

  # GET /fibra_redes
  # GET /fibra_redes.json
  def index
    @q = FibraRede.ransack(params[:q])
    @q.sorts = %w[ponto_nome nome]
    @fibra_redes = @q.result.page params[:page]
  end

  # GET /fibra_redes/1
  # GET /fibra_redes/1.json
  def show
    @fibra_rede = FibraRede.find(params[:id])
    @params = { rede_id: @fibra_rede }
    @fibra_caixas = @fibra_rede.fibra_caixas.order(:nome)
  end

  # GET /fibra_redes/new
  def new
    @fibra_rede = FibraRede.new
  end

  # GET /fibra_redes/1/edit
  def edit; end

  # POST /fibra_redes
  # POST /fibra_redes.json
  def create
    @fibra_rede = FibraRede.new(fibra_rede_params)

    respond_to do |format|
      if @fibra_rede.save
        format.html { redirect_to @fibra_rede, notice: 'Fibra rede was successfully created.' }
        format.json { render :show, status: :created, location: @fibra_rede }
      else
        format.html { render :new }
        format.json { render json: @fibra_rede.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fibra_redes/1
  # PATCH/PUT /fibra_redes/1.json
  def update
    respond_to do |format|
      if @fibra_rede.update(fibra_rede_params)
        format.html { redirect_to @fibra_rede, notice: 'Fibra rede was successfully updated.' }
        format.json { render :show, status: :ok, location: @fibra_rede }
      else
        format.html { render :edit }
        format.json { render json: @fibra_rede.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fibra_redes/1
  # DELETE /fibra_redes/1.json
  def destroy
    @fibra_rede.destroy
    respond_to do |format|
      format.html { redirect_to fibra_redes_url, notice: 'Fibra rede was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_fibra_rede
    @fibra_rede = FibraRede.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def fibra_rede_params
    params.require(:fibra_rede).permit(:nome, :ponto_id, :fibra_cor)
  end
end
