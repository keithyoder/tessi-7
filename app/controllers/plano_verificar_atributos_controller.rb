# frozen_string_literal: true

class PlanoVerificarAtributosController < ApplicationController
  before_action :set_plano_verificar_atributo, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /plano_verificar_atributos
  # GET /plano_verificar_atributos.json
  def index
    @q = PlanoVerificarAtributo.ransack(params[:q])
    @plano_verificar_atributos = @q.result(order: :atributo).page params[:page]
    respond_to do |format|
      format.html
      format.csv do
        send_data @plano_verificar_atributos.except(:limit, :offset).to_csv,
                  filename: "plano_verificar_atributos-#{Date.today}.csv"
      end
    end
  end

  # GET /plano_verificar_atributos/1
  # GET /plano_verificar_atributos/1.json
  def show; end

  # GET /plano_verificar_atributos/new
  def new
    @plano_verificar_atributo = PlanoVerificarAtributo.new
  end

  # GET /plano_verificar_atributos/1/edit
  def edit; end

  # POST /plano_verificar_atributos
  # POST /plano_verificar_atributos.json
  def create
    @plano_verificar_atributo = PlanoVerificarAtributo.new(plano_verificar_atributo_params)

    respond_to do |format|
      if @plano_verificar_atributo.save
        format.html do
          redirect_to @plano_verificar_atributo, notice: 'Plano verificar atributo was successfully created.'
        end
        format.json { render :show, status: :created, location: @plano_verificar_atributo }
      else
        format.html { render :new }
        format.json { render json: @plano_verificar_atributo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plano_verificar_atributos/1
  # PATCH/PUT /plano_verificar_atributos/1.json
  def update
    respond_to do |format|
      if @plano_verificar_atributo.update(plano_verificar_atributo_params)
        format.html do
          redirect_to @plano_verificar_atributo, notice: 'Plano verificar atributo was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @plano_verificar_atributo }
      else
        format.html { render :edit }
        format.json { render json: @plano_verificar_atributo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plano_verificar_atributos/1
  # DELETE /plano_verificar_atributos/1.json
  def destroy
    @plano_verificar_atributo.destroy
    respond_to do |format|
      format.html do
        redirect_to plano_verificar_atributos_url, notice: 'Plano verificar atributo was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_plano_verificar_atributo
    @plano_verificar_atributo = PlanoVerificarAtributo.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def plano_verificar_atributo_params
    params.require(:plano_verificar_atributo).permit(:plano_id, :atributo, :op, :valor)
  end
end
