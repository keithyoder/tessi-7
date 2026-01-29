# frozen_string_literal: true

class LogradourosController < ApplicationController
  load_and_authorize_resource

  # GET /logradouros
  def index
    if params[:search].present?
      @logradouros = Logradouro.accessible_by(current_ability)
        .name_like("%#{params[:search]}%")
        .order(:nome)
    else
      @q = Logradouro.accessible_by(current_ability)
        .eager_load(:bairro, :cidade, :estado)
        .ransack(params[:q])

      @q.sorts = ['nome'] if @q.sorts.empty?
      @logradouros = @q.result.page(params[:logradouros_page])
    end
    @params = {}
  end

  # GET /logradouros/1
  def show
    @conexoes = @logradouro.conexoes.page(params[:page])
    @params = params.permit(:tab)
  end

  # GET /logradouros/new
  def new
    @logradouro.bairro_id = params[:bairro_id] if params[:bairro_id].present?
  end

  # GET /logradouros/1/edit
  def edit; end

  # POST /logradouros
  def create
    if @logradouro.save
      redirect_to @logradouro, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /logradouros/1
  def update
    if @logradouro.update(logradouro_params)
      redirect_to @logradouro, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /logradouros/1
  def destroy
    @logradouro.destroy
    redirect_to logradouros_url, notice: t('.notice')
  end

  private

  def logradouro_params
    params.require(:logradouro).permit(:nome, :bairro_id, :cep)
  end
end
