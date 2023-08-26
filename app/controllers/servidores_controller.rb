# frozen_string_literal: true

class ServidoresController < ApplicationController
  before_action :set_servidor, only: %i[show edit update destroy backup mapa]
  load_and_authorize_resource

  # GET /servidores
  # GET /servidores.json
  def index
    @q = Servidor.ransack(params[:q])
    @q.sorts = 'nome'
    @servidores = @q.result.page params[:page]
    respond_to do |format|
      format.html
      format.csv do
        send_data @servidores.except(:limit, :offset).to_csv, filename: "concentradores  -#{Date.today}.csv"
      end
    end
  end

  # GET /servidores/1
  # GET /servidores/1.json
  def show
    @servidor = Servidor.find(params[:id])
    @q = @servidor.pontos.ransack(params[:q])
    @q.sorts = 'nome'
    @pontos = @q.result.page params[:page]
    @autenticacoes = @servidor.autenticacoes.order(authdate: :desc).page params[:page]
  end

  def backup
    @servidor.copiar_backup
    respond_to do |format|
      format.html { redirect_to @servidor, notice: 'Backup iniciado.' }
      format.json { head :no_content }
    end
  end

  def backups
    if request.format == :job
      MikrotikBackupJob.perform_later
    else
      @servidores = Servidor.ativo.order(:nome)
    end
    respond_to do |format|
      format.job do
        redirect_to backups_servidores_path, notice: 'Backup iniciado.'
      end
      format.html { render :backups }
      format.json { head :no_content }
    end
  end

  # GET /servidores/new
  def new
    @servidor = Servidor.new
  end

  # GET /servidores/1/edit
  def edit; end

  def mapa
    @conectadas = @servidor.conexoes
                           .conectada
                           .includes(:pessoa, :logradouro, :bairro, :ponto, :logradouro_pessoa)
                           .where.not(latitude: nil)
                           .to_json(include: %i[pessoa logradouro bairro ponto logradouro_pessoa])
    @desconectadas = @servidor.conexoes
                              .desconectada
                              .includes(:pessoa, :logradouro, :bairro, :ponto, :logradouro_pessoa)
                              .where.not(latitude: nil)
                              .to_json(include: %i[pessoa logradouro bairro ponto logradouro_pessoa])
    puts @desconectadas
  end

  # POST /servidores
  # POST /servidores.json
  def create
    @servidor = Servidor.new(servidor_params)

    respond_to do |format|
      if @servidor.save
        format.html do
          redirect_to @servidor, notice: 'Concentrador criado com sucesso.'
        end
        format.json { render :show, status: :created, location: @servidor }
      else
        format.html { render :new }
        format.json { render json: @servidor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /servidores/1
  # PATCH/PUT /servidores/1.json
  def update
    respond_to do |format|
      if @servidor.update(servidor_params)
        format.html { redirect_to @servidor, notice: 'Servidor was successfully updated.' }
        format.json { render :show, status: :ok, location: @servidor }
      else
        format.html { render :edit }
        format.json { render json: @servidor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /servidores/1
  # DELETE /servidores/1.json
  def destroy
    @servidor.destroy
    respond_to do |format|
      format.html { redirect_to servidores_url, notice: 'Servidor was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_servidor
    @servidor = Servidor.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def servidor_params
    params.require(:servidor).permit(
      :nome, :ip, :usuario, :senha, :api_porta, :ssh_porta, :snmp_porta,
      :snmp_comunidade, :radius_porta, :radius_secret, :ativo
    )
  end
end
