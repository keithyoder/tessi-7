# frozen_string_literal: true

class PontosController < ApplicationController
  include ConexoesHelper

  before_action :set_ponto, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /pontos
  # GET /pontos.json
  def index
    @q = Ponto.ransack(params[:q])
    @q.sorts = 'nome'
    @pontos = @q.result.page params[:page]
    respond_to do |format|
      format.html
      format.csv do
        send_data @pontos.except(:limit, :offset).to_csv, filename: "pontos-#{Time.zone.today}.csv"
      end
    end
  end

  def snmp
    AtualizarConcentradoresEPontosJob.perform_later
    respond_to do |format|
      format.html { redirect_to pontos_url, notice: 'Varredura SNMP inicada.' }
      format.json { head :no_content }
    end
  end

  # GET /pontos/1
  # GET /pontos/1.json
  def show
    @conexao_q = @ponto.conexoes.order(:ip).ransack(params[:conexao_q])
    @conexoes = @conexao_q.result.page params[:conexoes_page]
    @autenticacoes = @ponto.autenticacoes
    @ips = @ponto.ipv4_disponiveis if params.key?(:ipv4)
    @params = conexoes_params(params)
    respond_to do |format|
      format.html # show.html.erb
      format.kml
      format.geojson
      if params.key?(:ipv4)
        format.json { render json: @ips }
      else
        format.json
      end
    end
  end

  # GET /pontos/new
  def new
    @ponto = Ponto.new
  end

  # GET /pontos/1/edit
  def edit; end

  # POST /pontos
  # POST /pontos.json
  def create
    @ponto = Ponto.new(ponto_params)

    respond_to do |format|
      if @ponto.save
        format.html { redirect_to @ponto, notice: 'Ponto was successfully created.' }
        format.json { render :show, status: :created, location: @ponto }
      else
        format.html { render :new }
        format.json { render json: @ponto.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /pontos/1
  # PATCH/PUT /pontos/1.json
  def update
    respond_to do |format|
      if @ponto.update(ponto_params)
        format.html { redirect_to @ponto, notice: 'Ponto was successfully updated.' }
        format.json { render :show, status: :ok, location: @ponto }
      else
        format.html { render :edit }
        format.json { render json: @ponto.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /pontos/1
  # DELETE /pontos/1.json
  def destroy
    @ponto.destroy
    respond_to do |format|
      format.html { redirect_to pontos_url, notice: 'Ponto was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ponto
    @ponto = Ponto.includes(
      :servidor,
      :redes,
      :caixas,
      :ip_redes,
      conexoes: %i[pessoa plano]
    ).find(params[:id])

    # Group conexoes by IP range for efficient lookup
    if @ponto.ip_redes.loaded? && @ponto.conexoes.loaded?
      @conexoes_by_rede = group_conexoes_by_ip_rede(@ponto.ip_redes, @ponto.conexoes)
    end

    # Batch check connection status (prevents N+1 on rad_accts)
    return unless @ponto.conexoes.loaded?

    @conexoes_status = Conexao.status_conexoes(@ponto.conexoes)
  end

  def group_conexoes_by_ip_rede(ip_redes, conexoes)
    ip_redes.each_with_object({}) do |rede, hash|
      next unless rede.cidr

      begin
        cidr_range = IPAddr.new(rede.cidr)

        hash[rede.id] = conexoes.select do |conexao|
          next false unless conexao.ip

          begin
            cidr_range.include?(IPAddr.new(conexao.ip.to_s))
          rescue IPAddr::InvalidAddressError
            false
          end
        end
      rescue IPAddr::InvalidAddressError
        hash[rede.id] = []
      end
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ponto_params
    params.require(:ponto).permit(
      :nome, :sistema, :tecnologia, :servidor_id, :ip, :usuario, :senha, :equipamento, :ipv6
    )
  end
end
