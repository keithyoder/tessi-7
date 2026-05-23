# frozen_string_literal: true

class PlanosController < ApplicationController
  load_and_authorize_resource

  # GET /planos
  def index
    params[:q] ||= {}
    params[:q][:ativo_eq] = 'true' if params[:q][:ativo_eq].nil?

    @q = Plano.accessible_by(current_ability).ransack(params[:q])
    @q.sorts = 'nome' if @q.sorts.empty?
    @search_params = @q.conditions.to_h { |c| [c.attributes.first, c.values.first] }

    @pagy, @planos = pagy(@q.result, limit: 12)
  end

  # GET /planos/1
  def show
    @plano_verificar_atributos = @plano.plano_verificar_atributos
    @plano_enviar_atributos = @plano.plano_enviar_atributos
  end

  # GET /planos/new
  def new; end

  # GET /planos/1/edit
  def edit; end

  # POST /planos
  def create
    if @plano.save
      redirect_to @plano, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /planos/1
  def update
    if @plano.update(plano_params)
      redirect_to @plano, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /planos/1
  def destroy
    @plano.destroy
    redirect_to planos_url, notice: t('.notice')
  end

  private

  def plano_params
    params.require(:plano).permit(
      :nome, :mensalidade, :upload, :download, :burst, :desconto, :ativo
    )
  end
end
