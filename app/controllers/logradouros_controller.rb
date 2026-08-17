# frozen_string_literal: true

class LogradourosController < ApplicationController
  load_and_authorize_resource

  # GET /logradouros
  def index
    respond_to do |format|
      format.json do
        @logradouros = Logradouro.accessible_by(current_ability)
          .where('logradouros.nome ILIKE ?', "%#{params[:search]}%")
          .eager_load(:bairro, :cidade, :estado)
          .order(:nome)
          .limit(10)
      end

      format.html do
        @q = Logradouro.accessible_by(current_ability)
          .eager_load(:bairro, :cidade, :estado)
          .ransack(params[:q])

        @q.sorts = ['nome'] if @q.sorts.empty?
        @logradouros = @q.result.page(params[:logradouros_page])
        @params = {}
      end
    end
  end

  # GET /logradouros/1
  def show
    @pagy_conexoes, @conexoes = pagy(@logradouro.conexoes, page_param: :conexoes_page)
    @conexoes_status = Conexao.status_conexoes(@conexoes)
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
