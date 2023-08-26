# frozen_string_literal: true

class PlanoEnviarAtributosController < ApplicationController
  before_action :set_plano_enviar_atributo, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /plano_enviar_atributos
  # GET /plano_enviar_atributos.json
  def index
    @q = PlanoEnviarAtributo.ransack(params[:q])
    @plano_enviar_atributos = @q.result(order: :atributo).page params[:page]
    respond_to do |format|
      format.html
      format.csv do
        send_data @plano_enviar_atributos.except(:limit, :offset).to_csv,
                  filename: "plano_enviar_atributos-#{Date.today}.csv"
      end
    end
  end

  # GET /plano_enviar_atributos/1
  # GET /plano_enviar_atributos/1.json
  def show; end

  # GET /plano_enviar_atributos/new
  def new
    @plano_enviar_atributo = PlanoEnviarAtributo.new
  end

  # GET /plano_enviar_atributos/1/edit
  def edit; end

  # POST /plano_enviar_atributos
  # POST /plano_enviar_atributos.json
  def create
    @plano_enviar_atributo = PlanoEnviarAtributo.new(plano_enviar_atributo_params)

    respond_to do |format|
      if @plano_enviar_atributo.save
        format.html { redirect_to @plano_enviar_atributo, notice: 'Plano enviar atributo was successfully created.' }
        format.json { render :show, status: :created, location: @plano_enviar_atributo }
      else
        format.html { render :new }
        format.json { render json: @plano_enviar_atributo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plano_enviar_atributos/1
  # PATCH/PUT /plano_enviar_atributos/1.json
  def update
    respond_to do |format|
      if @plano_enviar_atributo.update(plano_enviar_atributo_params)
        format.html { redirect_to @plano_enviar_atributo, notice: 'Plano enviar atributo was successfully updated.' }
        format.json { render :show, status: :ok, location: @plano_enviar_atributo }
      else
        format.html { render :edit }
        format.json { render json: @plano_enviar_atributo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plano_enviar_atributos/1
  # DELETE /plano_enviar_atributos/1.json
  def destroy
    @plano_enviar_atributo.destroy
    respond_to do |format|
      format.html do
        redirect_to plano_enviar_atributos_url, notice: 'Plano enviar atributo was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_plano_enviar_atributo
    @plano_enviar_atributo = PlanoEnviarAtributo.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def plano_enviar_atributo_params
    params.require(:plano_enviar_atributo).permit(:plano_id, :atributo, :op, :valor)
  end
end
