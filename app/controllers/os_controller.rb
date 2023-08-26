# frozen_string_literal: true

class OsController < ApplicationController
  before_action :set_os, only: %i[show edit update destroy]
  before_action :set_scope, only: %i[index show new]
  layout 'print', only: [:impressao]
  load_and_authorize_resource

  # GET /os or /os.json
  def index
    @os = Os
    @os = @os.abertas if params.key?(:abertas)
    @os = @os.fechadas if params.key?(:fechadas)
    @os = @os.por_responsavel(current_user) if params.key?(:minhas)
    @os = @os.por_responsavel(params[:responsavel]) if params.key?(:responsavel)
    @os_q = @os.includes(:pessoa, :classificacao).order(created_at: :asc).ransack(params[:os_q])
    @os = @os_q.result.page params[:page]
    respond_to do |format|
      format.html
    end
  end

  # GET /os/1 or /os/1.json
  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render :show }
      format.pdf do
        render pdf: 'show', encoding: 'UTF-8', zoom: 1.2, margin: { top: 15, bottom: 15, left: 15, right: 15 },
               page_size: 'A4'
      end
    end
  end

  # GET /os/new
  def new
    @os = Os.new
    @os.pessoa_id = params[:pessoa_id] if params.key?(:pessoa_id)
    @os.aberto_por = @current_user
    @os.responsavel = @current_user
  end

  # GET /os/1/edit
  def edit; end

  # POST /os or /os.json
  def create
    @os = Os.new(os_params)

    respond_to do |format|
      if @os.save
        format.html { redirect_to @os, notice: 'OS criada com sucesso.' }
        format.json { render :show, status: :created, location: @os }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @os.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /os/1 or /os/1.json
  def update
    @os.fechamento = Time.zone.now if params[:commit].present? && params[:commit] == 'Encerrar'
    respond_to do |format|
      if @os.update(os_params.except(:fechamento))
        format.html { redirect_to @os, notice: 'OS atualizada com sucesso.' }
        format.json { render :show, status: :ok, location: @os }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @os.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /os/1 or /os/1.json
  def destroy
    @os.destroy
    respond_to do |format|
      format.html { redirect_to os_index_url, notice: 'Os was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_os
    @os = Os.find(params[:id])
  end

  def set_scope
    @params = params.permit(:abertas, :fechadas, :minhas, :responsavel)
  end

  # Only allow a list of trusted parameters through.
  def os_params
    params.require(:os).permit(
      :tipo, :classificacao_id, :pessoa_id, :conexao_id, :aberto_por_id,
      :responsavel_id, :tecnico_1_id, :tecnico_2_id, :fechamento,
      :descricao, :encerramento
    )
  end
end
