# frozen_string_literal: true

class OsController < ApplicationController
  include TurboFrameIndex

  before_action :set_os, only: %i[show edit update destroy]
  before_action :set_params_for_legacy_header, only: %i[show]

  escopavel_por :pessoa_id, :conexao_id, :servidor_id, :ponto_id

  authorize_resource

  # GET /os
  def index
    @q = escopo.includes(:pessoa, :classificacao).ransack(params[:q])
    @q.sorts = 'created_at asc' if @q.sorts.empty?
    @search_params = params.fetch(:q, {}).permit(:pessoa_nome_cont, :tipo_eq, :cidade, :fechamento_null).to_h

    @pagy, @os = pagy(@q.result, limit: 15)
  end

  # GET /os/1
  def show
    respond_to do |format|
      format.html { render :show }
      format.pdf do
        render pdf: 'show', encoding: 'UTF-8', zoom: 1.2, margin: { top: 15, bottom: 15, left: 15, right: 15 },
               page_size: 'A4'
      end
    end
  end

  # GET /os/new
  def new
    @os = Os.new(
      pessoa_id: params[:pessoa_id],
      infraestrutura_type: params[:infraestrutura_type],
      infraestrutura_id: params[:infraestrutura_id],
      aberto_por: current_user,
      responsavel: current_user
    )
  end

  # GET /os/1/edit
  def edit; end

  # POST /os
  def create
    @os = Os.new(os_params)
    @os.aberto_por = current_user

    if @os.save
      Os::MelhorarDescricaoJob.perform_later(@os.id)
      redirect_to @os, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /os/1
  def update
    if @os.update(os_params)
      redirect_to @os, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /os/1
  def destroy
    @os.destroy!
    redirect_to os_index_url, notice: t('.notice')
  end

  private

  def set_os
    @os = Os.find(params[:id])
  end

  def set_params_for_legacy_header
    @params = params
  end

  # Os não tem servidor_id/ponto_id como coluna — a infraestrutura é
  # polimórfica (infraestrutura_type/infraestrutura_id). Por isso o
  # escopo aqui traduz servidor_id/ponto_id manualmente em vez de usar
  # o aplicar_escopo genérico do concern.
  def escopo # rubocop:disable Metrics/AbcSize
    consulta = Os.all
    consulta = consulta.where(pessoa_id: params[:pessoa_id]) if params[:pessoa_id].present?
    consulta = consulta.where(conexao_id: params[:conexao_id]) if params[:conexao_id].present?
    if params[:servidor_id].present?
      consulta = consulta.where(infraestrutura_type: 'Servidor', infraestrutura_id: params[:servidor_id])
    end
    if params[:ponto_id].present?
      consulta = consulta.where(infraestrutura_type: 'Ponto',
                                infraestrutura_id: params[:ponto_id])
    end
    consulta
  end

  def os_params
    params.require(:os).permit(
      :aberto_por_id, :classificacao_id, :conexao_id, :descricao,
      :infraestrutura_type, :infraestrutura_id,
      :pessoa_id, :responsavel_id, :tecnico_1_id, :tecnico_2_id, :tipo
    )
  end
end
