# frozen_string_literal: true

class PagamentoPerfisController < ApplicationController
  load_and_authorize_resource
  before_action :set_pagamento_perfil, only: %i[remessa]

  # GET /pagamento_perfis
  def index
    @pagamento_perfis = PagamentoPerfil.accessible_by(current_ability).order(:nome)
  end

  # GET /pagamento_perfis/1
  def show
    @retornos = @pagamento_perfil.retornos.order(data: :desc).page(params[:page])

    @faturas = @pagamento_perfil.faturas
      .accessible_by(current_ability)
      .eager_load(:contrato, :pessoa)
      .em_aberto
      .where(vencimento: ...1.week.from_now)
      .order(:vencimento)
      .ransack.result
      .page(params[:page])
  end

  # GET /pagamento_perfis/new
  def new; end

  # GET /pagamento_perfis/1/edit
  def edit; end

  # GET /pagamento_perfis/1/remessa
  def remessa
    @pagamento_perfil.update!(sequencia: params[:sequencia])

    send_data(
      @pagamento_perfil.remessa(params[:sequencia]).gera_arquivo,
      content_type: 'text/plain',
      disposition: 'attachment',
      filename: "#{@pagamento_perfil.banco.to_s.rjust(3, '0')}-#{Time.now.strftime('%Y-%m-%d')}.rem"
    )
  end

  # POST /pagamento_perfis
  def create
    if @pagamento_perfil.save
      redirect_to @pagamento_perfil, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /pagamento_perfis/1
  def update
    if @pagamento_perfil.update(pagamento_perfil_params)
      redirect_to @pagamento_perfil, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /pagamento_perfis/1
  def destroy
    @pagamento_perfil.destroy
    redirect_to pagamento_perfis_url, notice: t('.notice')
  end

  private

  def pagamento_perfil_params
    params.require(:pagamento_perfil).permit(
      :nome, :tipo, :cedente, :agencia, :conta, :carteira,
      :banco, :variacao, :sequencia, :ativo
    )
  end
end
