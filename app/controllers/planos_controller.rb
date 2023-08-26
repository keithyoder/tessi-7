# frozen_string_literal: true

class PlanosController < ApplicationController
  before_action :set_plano, only: %i[show edit update destroy ips]
  load_and_authorize_resource

  # GET /planos
  # GET /planos.json
  def index
    @q = Plano.ransack(params[:q])
    @q.sorts = 'nome'
    @planos = @q.result.page params[:page]
    respond_to do |format|
      format.html
      format.csv { send_data @planos.except(:limit, :offset).to_csv, filename: "planos-#{Date.today}.csv" }
    end
  end

  # GET /planos/1
  # GET /planos/1.json
  def show
    @plano_verificar_atributos = @plano.plano_verificar_atributos
    @plano_enviar_atributos = @plano.plano_enviar_atributos
  end

  # GET /planos/new
  def new
    @plano = Plano.new
  end

  # GET /planos/1/edit
  def edit; end

  # POST /planos
  # POST /planos.json
  def create
    @plano = Plano.new(plano_params)

    respond_to do |format|
      if @plano.save
        format.html { redirect_to @plano, notice: 'Plano was successfully created.' }
        format.json { render :show, status: :created, location: @plano }
      else
        format.html { render :new }
        format.json { render json: @plano.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /planos/1
  # PATCH/PUT /planos/1.json
  def update
    respond_to do |format|
      if @plano.update(plano_params)
        format.html { redirect_to @plano, notice: 'Plano was successfully updated.' }
        format.json { render :show, status: :ok, location: @plano }
      else
        format.html { render :edit }
        format.json { render json: @plano.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /planos/1
  # DELETE /planos/1.json
  def destroy
    @plano.destroy
    respond_to do |format|
      format.html { redirect_to planos_url, notice: 'Plano was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_plano
    @plano = Plano.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def plano_params
    params.require(:plano).permit(
      :nome, :mensalidade, :upload, :download, :burst, :page, :desconto, :ativo
    )
  end
end
