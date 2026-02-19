# frozen_string_literal: true

class PontosController < ApplicationController
  include ConexoesHelper

  authorize_resource
  before_action :set_ponto, only: %i[edit update destroy]
  before_action :set_ponto_with_details, only: %i[show]
  before_action :set_available_devices, only: %i[new edit create update]

  def index
    @q = Ponto.ransack(params[:q])
    @q.sorts = 'nome'
    @search_params = params[:q]&.to_unsafe_h || {}

    @pagy, @pontos = pagy(
      @q.result
        .left_joins(:conexoes)
        .select(
          'pontos.*',
          'COUNT(conexoes.id) AS conexoes_count',
          'COUNT(CASE WHEN conexoes.bloqueado THEN 1 END) AS bloqueadas_count'
        )
        .group('pontos.id')
        .includes(:servidor)
    )
  end

  def snmp
    AtualizarConcentradoresEPontosJob.perform_later
    redirect_to pontos_url, notice: t('.sucesso')
  end

  def show
    @conexao_q = @ponto
      .conexoes
      .includes(:pessoa, :plano)
      .order(:ip)
      .ransack(params[:conexao_q])

    @pagy_conexoes, @conexoes = pagy(@conexao_q.result, page_param: :conexoes_page)
    @conexoes_status = Conexao.status_conexoes(@conexoes)
    @autenticacoes = @ponto.autenticacoes
    @ips = @ponto.ipv4_disponiveis if params.key?(:ipv4)
    @params = conexoes_params(params)

    respond_to do |format|
      format.html
      format.kml
      format.geojson
    end
  end

  def new
    @ponto = Ponto.new
  end

  def edit; end

  def create
    @ponto = Ponto.new(ponto_params)

    if @ponto.save
      redirect_to @ponto, notice: t('.sucesso')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @ponto.update(ponto_params)
      redirect_to @ponto, notice: t('.sucesso')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @ponto.destroy
    redirect_to pontos_url, notice: t('.sucesso')
  end

  private

  def set_ponto
    @ponto = Ponto.find(params[:id])
  end

  def set_ponto_with_details
    @ponto = Ponto.includes(
      :servidor,
      :redes,
      :caixas,
      :ip_redes,
      device: :equipamento,
      conexoes: %i[pessoa plano]
    ).find(params[:id])

    return unless @ponto.ip_redes.loaded? && @ponto.conexoes.loaded?

    @conexoes_by_rede = IpRede.agrupar_conexoes(@ponto.ip_redes, @ponto.conexoes)
    @conexoes_status = Conexao.status_conexoes(@ponto.conexoes)
  end

  def ponto_params
    params.require(:ponto).permit(
      :nome, :sistema, :tecnologia, :servidor_id, :ip, :ipv6, :device_id
    )
  end

  def set_available_devices
    devices = Device.unlinked.order(:mac)
    devices = devices.or(Device.where(id: @ponto.device&.id)) if @ponto&.device
    @available_devices = devices
  end
end
