# frozen_string_literal: true

class FibraCaixasController < ApplicationController
  include ConexoesHelper

  load_and_authorize_resource

  # GET /fibra_caixas
  def index
    @fibra_caixas = FibraCaixa.accessible_by(current_ability)
  end

  # GET /fibra_caixas/1
  def show
    @q = @fibra_caixa
      .conexoes
      .includes(:pessoa, :plano, :ponto, :equipamento)
      .ransack(params[:q])

    @q.sorts = 'ip' if @q.sorts.empty?

    @params = conexoes_params(params)

    @pagy_conexoes, @conexoes = pagy(@q.result, page_param: :conexoes_page)

    @conexoes_status = Conexao.status_conexoes(@conexoes)

    montar_mapa
  end

  # GET /fibra_caixas/new
  def new; end

  # GET /fibra_caixas/1/edit
  def edit; end

  # POST /fibra_caixas
  def create
    if @fibra_caixa.save
      redirect_to @fibra_caixa, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /fibra_caixas/1
  def update
    if @fibra_caixa.update(fibra_caixa_params)
      redirect_to @fibra_caixa, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /fibra_caixas/1
  def destroy
    @fibra_caixa.destroy
    redirect_to fibra_caixas_url, notice: t('.notice')
  end

  private

  def fibra_caixa_params
    params.require(:fibra_caixa).permit(
      :nome,
      :fibra_rede_id,
      :capacidade,
      :poste,
      :logradouro_id,
      :latitude,
      :longitude,
      :fibra_cor
    )
  end

  private

  def montar_mapa
    conexoes_mapa = @fibra_caixa
      .conexoes
      .joins(:pessoa)
      .where.not(latitude: nil, longitude: nil)
      .select('conexoes.id, conexoes.latitude, conexoes.longitude, conexoes.usuario, pessoas.nome AS pessoa_nome')

    mapa_status = Conexao.status_conexoes(conexoes_mapa)

    conexao_markers = conexoes_mapa.map do |c|
      online = mapa_status[c.id]
      {
        lat: c.latitude,
        lng: c.longitude,
        color: online ? '#198754' : '#dc3545',
        title: c.pessoa_nome,
        popup: "#{online ? '🟢' : '🔴'} #{c.pessoa_nome}"
      }
    end

    caixa_marker = if @fibra_caixa.latitude.present? && @fibra_caixa.longitude.present?
                     [{
                       lat: @fibra_caixa.latitude,
                       lng: @fibra_caixa.longitude,
                       color: '#0d6efd',
                       title: @fibra_caixa.nome,
                       popup: "<strong>📦 #{@fibra_caixa.nome}</strong>",
                       zIndexOffset: 1000
                     }]
                   else
                     []
                   end

    @markers = conexao_markers + caixa_marker # caixa por último, renderiza por cima
    first = caixa_marker.first || conexao_markers.first
    @map_center = first ? [first[:lat], first[:lng]] : [-8.9, -36.4]
  end
end
