# frozen_string_literal: true

class PlanosController < ApplicationController
  load_and_authorize_resource

  # GET /planos
  def index
    @q = Plano.accessible_by(current_ability).ransack(params[:q])
    @q.sorts = 'nome' if @q.sorts.empty?

    @planos = @q.result.page(params[:page])

    respond_to do |format|
      format.html
      format.csv do
        send_data @planos.except(:limit, :offset).to_csv,
                  filename: "planos-#{Time.zone.today}.csv"
      end
    end
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
      :nome, :mensalidade, :upload, :download, :burst, :page, :desconto, :ativo
    )
  end
end
