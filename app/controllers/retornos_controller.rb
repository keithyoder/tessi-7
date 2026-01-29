# frozen_string_literal: true

class RetornosController < ApplicationController
  load_and_authorize_resource

  # GET /retornos
  def index
    @q = Retorno.joins(:pagamento_perfil)
      .where.not(pagamento_perfis: { banco: 364 })
      .accessible_by(current_ability)
      .ransack(params[:q])

    @q.sorts = 'data desc' if @q.sorts.empty?
    @retornos = @q.result.page(params[:page])
  end

  # GET /retornos/1
  def show
    @faturas = Fatura.where(pagamento_perfil: @retorno.pagamento_perfil)
    @linhas  = @retorno.carregar_arquivo
  end

  # GET /retornos/new
  def new; end

  # GET /retornos/1/edit
  def edit; end

  # POST /retornos
  def create
    if @retorno.save
      redirect_to @retorno, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /retornos/1
  def update
    @retorno.processar
    redirect_to @retorno, notice: t('.notice')
  rescue StandardError => e
    redirect_to @retorno, alert: e.message
  end

  # DELETE /retornos/1
  def destroy
    @retorno.destroy
    redirect_to retornos_url, notice: t('.notice')
  end

  private

  def retorno_params
    params.require(:retorno).permit(:pagamento_perfil_id, :data, :sequencia, :arquivo)
  end
end
