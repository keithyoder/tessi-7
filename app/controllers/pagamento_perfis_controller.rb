# frozen_string_literal: true

class PagamentoPerfisController < ApplicationController
  load_and_authorize_resource
  before_action :set_pagamento_perfil, only: %i[show edit update destroy remessa]

  # GET /pagamento_perfis
  # GET /pagamento_perfis.json
  def index
    @pagamento_perfis = PagamentoPerfil.order('nome').all
  end

  # GET /pagamento_perfis/1
  # GET /pagamento_perfis/1.json
  def show
    @retornos = @pagamento_perfil.retornos.order(data: :desc).page params[:page]
    @faturas = @pagamento_perfil.faturas
                                .eager_load(:contrato, :pessoa)
                                .em_aberto.where('vencimento < ?', 1.week.from_now)
                                .order(:vencimento)
                                .ransack.result.page(params[:page])
  end

  # GET /pagamento_perfis/new
  def new
    @pagamento_perfil = PagamentoPerfil.new
  end

  # GET /pagamento_perfis/1/edit
  def edit; end

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
  # POST /pagamento_perfis.json
  def create
    @pagamento_perfil = PagamentoPerfil.new(pagamento_perfil_params)

    respond_to do |format|
      if @pagamento_perfil.save
        format.html { redirect_to @pagamento_perfil, notice: 'Pagamento perfil was successfully created.' }
        format.json { render :show, status: :created, location: @pagamento_perfil }
      else
        format.html { render :new }
        format.json { render json: @pagamento_perfil.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pagamento_perfis/1
  # PATCH/PUT /pagamento_perfis/1.json
  def update
    respond_to do |format|
      if @pagamento_perfil.update(pagamento_perfil_params)
        format.html { redirect_to @pagamento_perfil, notice: 'Pagamento perfil was successfully updated.' }
        format.json { render :show, status: :ok, location: @pagamento_perfil }
      else
        format.html { render :edit }
        format.json { render json: @pagamento_perfil.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pagamento_perfis/1
  # DELETE /pagamento_perfis/1.json
  def destroy
    @pagamento_perfil.destroy
    respond_to do |format|
      format.html { redirect_to pagamento_perfis_url, notice: 'Pagamento perfil was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_pagamento_perfil
    @pagamento_perfil = PagamentoPerfil.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def pagamento_perfil_params
    params.require(:pagamento_perfil).permit(
      :nome, :tipo, :cedente, :agencia, :conta, :carteira, :banco, :conta,
      :variacao, :sequencia, :ativo
    )
  end
end
