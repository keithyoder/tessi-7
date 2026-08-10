# frozen_string_literal: true

class OsController < ApplicationController
  before_action :set_os, only: %i[show edit update destroy]
  before_action :set_params_for_legacy_header, only: %i[show]

  layout -> { turbo_frame_request? ? false : 'application' }
  authorize_resource

  # Parâmetros pelos quais uma OS pode ser filtrada quando exibida dentro
  # da aba de outro recurso (Pessoa, Conexao).
  PARAMETROS_ESCOPO = %i[pessoa_id conexao_id].freeze

  helper_method :id_frame, :incorporado?

  # GET /os
  def index
    @q = escopo_base.includes(:pessoa, :classificacao).ransack(params[:q])
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
    @os = Os.new(pessoa_id: params[:pessoa_id], aberto_por: current_user, responsavel: current_user)
  end

  # GET /os/1/edit
  def edit; end

  # POST /os
  def create
    @os = Os.new(os_params)

    if @os.save
      redirect_to @os, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /os/1
  def update
    @os.fechamento = Time.current if params[:commit] == 'Encerrar'

    if @os.update(os_params.except(:fechamento))
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

  # Verdadeiro quando a index está sendo exibida como aba incorporada
  # (Pessoa, Conexao) em vez da página avulsa /os.
  def incorporado?
    PARAMETROS_ESCOPO.any? { |parametro| params[parametro].present? }
  end

  # Id do turbo-frame da index. Na página avulsa usa um id fixo; quando
  # incorporada, gera um id compatível com a aba, ex. "pessoa_5_os".
  def id_frame
    escopo = PARAMETROS_ESCOPO.find { |parametro| params[parametro].present? }
    return 'os_index' unless escopo

    "#{escopo.to_s.delete_suffix('_id')}_#{params[escopo]}_os"
  end

  def escopo_base
    consulta = Os.all
    PARAMETROS_ESCOPO.each do |parametro|
      consulta = consulta.where(parametro => params[parametro]) if params[parametro].present?
    end
    consulta
  end

  def os_params
    params.require(:os).permit(
      :aberto_por_id, :classificacao_id, :conexao_id, :descricao, :encerramento,
      :fechamento, :pessoa_id, :responsavel_id, :tecnico_1_id, :tecnico_2_id, :tipo
    )
  end
end
