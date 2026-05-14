# frozen_string_literal: true

class FibraRedesController < ApplicationController
  authorize_resource
  before_action :set_fibra_rede, only: %i[show edit update destroy]

  def index
    @q = FibraRede.ransack(params[:q])
    @q.sorts = %w[ponto_nome nome] if @q.sorts.empty?
    @pagy, @fibra_redes = pagy(@q.result.includes(:ponto), items: 10)

    rede_ids = @fibra_redes.map(&:id)
    @total_por_rede = conexoes_por_rede(rede_ids)
    @online_por_rede = conexoes_online_por_rede(rede_ids)
  end

  def show
    @fibra_caixas = @fibra_rede.fibra_caixas.includes(:logradouro, :fibra_rede).order(:nome)

    caixa_ids = @fibra_caixas.map(&:id)

    @total_por_caixa = Conexao
      .where(caixa_id: caixa_ids)
      .group(:caixa_id)
      .count

    @conexoes_mapa = Conexao
      .joins(:pessoa)
      .where(caixa_id: caixa_ids)
      .where.not(latitude: nil, longitude: nil)
      .select('conexoes.id, conexoes.latitude, conexoes.longitude, conexoes.usuario, pessoas.nome AS pessoa_nome')

    @conexoes_status = Conexao.status_conexoes(@conexoes_mapa)

    online_conexao_ids = @conexoes_status.select { |_, v| v }.keys.to_set

    @online_por_caixa = Conexao
      .where(caixa_id: caixa_ids)
      .where(id: online_conexao_ids.any? ? online_conexao_ids : @conexoes_mapa.map(&:id))
      .group(:caixa_id)
      .count
      .tap { |h| h.transform_values! { 0 } unless online_conexao_ids.any? }

    @total_conexoes = @total_por_caixa.values.sum
    @total_ativas = @conexoes_status.count { |_, v| v }

    caixa_markers = @fibra_caixas
      .where.not(latitude: nil, longitude: nil)
      .map do |c|
        {
          lat: c.latitude,
          lng: c.longitude,
          color: '#0d6efd',
          title: c.nome,
          popup: "<strong>📦 #{c.nome}</strong>",
          zIndexOffset: 1000
        }
      end

    conexao_markers = @conexoes_mapa.map do |c|
      online = @conexoes_status[c.id]
      {
        lat: c.latitude,
        lng: c.longitude,
        color: online ? '#198754' : '#dc3545',
        title: c.pessoa_nome,
        popup: "#{online ? '🟢' : '🔴'} #{c.pessoa_nome}"
      }
    end

    @markers = conexao_markers + caixa_markers # caixas last so they render on top
    first = caixa_markers.first || conexao_markers.first
    @map_center = first ? [first[:lat], first[:lng]] : [-8.9, -36.4]
  end

  def new
    @fibra_rede = FibraRede.new
  end

  def edit; end

  def create
    if @fibra_rede.save
      redirect_to @fibra_rede, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @fibra_rede.update(fibra_rede_params)
      redirect_to @fibra_rede, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @fibra_rede.destroy
    redirect_to fibra_redes_url, notice: t('.notice')
  end

  private

  def set_fibra_rede
    @fibra_rede = FibraRede.find(params[:id])
  end

  def fibra_rede_params
    params.require(:fibra_rede).permit(:nome, :ponto_id, :fibra_cor)
  end

  def conexoes_por_rede(rede_ids)
    Conexao
      .joins(:caixa)
      .where(fibra_caixas: { fibra_rede_id: rede_ids })
      .group('fibra_caixas.fibra_rede_id')
      .count
  end

  def conexoes_online_por_rede(rede_ids)
    online_ids = Conexao
      .select('conexoes.id')
      .joins(:rad_accts)
      .where('AcctStartTime > ? AND AcctStopTime IS NULL', 2.days.ago)
      .group('conexoes.id')

    Conexao
      .joins(:caixa)
      .where(fibra_caixas: { fibra_rede_id: rede_ids })
      .where(id: online_ids)
      .group('fibra_caixas.fibra_rede_id')
      .count
  end
end
