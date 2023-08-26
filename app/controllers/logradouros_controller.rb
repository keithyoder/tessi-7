# frozen_string_literal: true

class LogradourosController < ApplicationController
  before_action :set_logradouro, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /logradouros
  # GET /logradouros.json
  def index
    if params[:search]
      @logradouros = Logradouro.name_like("%#{params[:search]}%").order('nome')
    else
      @q = Logradouro.ransack(params[:q])
      @logradouros = @q.result(order: :nome).page params[:logradouros_page]
    end
    @params = {}
  end

  # GET /logradouros/1
  # GET /logradouros/1.json
  def show
    @logradouro = Logradouro.find(params[:id])
    @conexoes = @logradouro.conexoes.page params[:page]
    @params = params.permit(:tab)
  end

  # GET /logradouros/new
  def new
    @logradouro = Logradouro.new
    @logradouro.bairro_id = params[:bairro_id]
  end

  # GET /logradouros/1/edit
  def edit; end

  # POST /logradouros
  # POST /logradouros.json
  def create
    @logradouro = Logradouro.new(logradouro_params)

    respond_to do |format|
      if @logradouro.save
        format.html { redirect_to @logradouro, notice: 'Logradouro was successfully created.' }
        format.json { render :show, status: :created, location: @logradouro }
      else
        format.html { render :new }
        format.json { render json: @logradouro.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /logradouros/1
  # PATCH/PUT /logradouros/1.json
  def update
    respond_to do |format|
      if @logradouro.update(logradouro_params)
        format.html { redirect_to @logradouro, notice: 'Logradouro was successfully updated.' }
        format.json { render :show, status: :ok, location: @logradouro }
      else
        format.html { render :edit }
        format.json { render json: @logradouro.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /logradouros/1
  # DELETE /logradouros/1.json
  def destroy
    @logradouro.destroy
    respond_to do |format|
      format.html { redirect_to logradouros_url, notice: 'Logradouro was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_logradouro
    @logradouro = Logradouro.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def logradouro_params
    params.require(:logradouro).permit(:nome, :bairro_id, :cep)
  end
end
