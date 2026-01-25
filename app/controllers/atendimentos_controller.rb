# frozen_string_literal: true

class AtendimentosController < ApplicationController
  before_action :set_scope, only: %i[index show new]
  before_action :set_atendimento, only: [:encerrar]
  load_and_authorize_resource

  # GET /atendimentos or /atendimentos.json
  def index
    @q = build_query.ransack(params[:q])
    @q.sorts = 'created_at' if @q.sorts.empty?
    @atendimentos = @q.result.page(params[:page])

    respond_to do |format|
      format.html
    end
  end

  # GET /atendimentos/1 or /atendimentos/1.json
  def show; end

  # GET /atendimentos/new
  def new
    @atendimento = Atendimento.new(
      pessoa_id: params[:pessoa_id],
      responsavel: current_user
    )
    @detalhe = AtendimentoDetalhe.new(atendimento: @atendimento)
  end

  # GET /atendimentos/1/edit
  def edit; end

  # PATCH /atendimentos/1/encerrar
  def encerrar
    authorize! :encerrar, @atendimento

    @atendimento.update!(fechamento: Time.current)

    respond_to do |format|
      format.html { redirect_to @atendimento, notice: t('.notice') }
      format.json { render :show, status: :ok, location: @atendimento }
    end
  end

  # POST /atendimentos or /atendimentos.json
  def create
    result = Atendimentos::CriarService.call(
      atendimento_params: atendimento_params.except(:detalhe_tipo, :detalhe_descricao),
      detalhe_tipo: atendimento_params[:detalhe_tipo],
      detalhe_descricao: atendimento_params[:detalhe_descricao],
      atendente: current_user
    )

    @atendimento = result[:atendimento]
    @detalhe = result[:detalhe]

    respond_to do |format|
      if result[:success]
        format.html { redirect_to @atendimento, notice: t('.notice') }
        format.json { render :show, status: :created, location: @atendimento }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @atendimento.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /atendimentos/1 or /atendimentos/1.json
  def update
    respond_to do |format|
      if @atendimento.update(atendimento_params.except(:detalhe_tipo, :detalhe_descricao))
        format.html { redirect_to @atendimento, notice: t('.notice') }
        format.json { render :show, status: :ok, location: @atendimento }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @atendimento.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /atendimentos/1 or /atendimentos/1.json
  def destroy
    @atendimento.destroy!

    respond_to do |format|
      format.html { redirect_to atendimentos_url, notice: t('.notice') }
      format.json { head :no_content }
    end
  end

  private

  def set_atendimento
    @atendimento = Atendimento.find(params[:id])
  end

  def set_scope
    @params = params.permit(:abertos, :fechados, :meus, :responsavel)
  end

  def atendimento_params
    params.require(:atendimento).permit(
      :pessoa_id, :classificacao_id, :responsavel_id, :fechamento, :contrato_id,
      :conexao_id, :fatura_id, :detalhe_tipo, :detalhe_descricao
    )
  end

  def build_query
    query = Atendimento.all
    query = query.abertos if params.key?(:abertos)
    query = query.fechados if params.key?(:fechados)
    query = query.por_responsavel(current_user) if params.key?(:meus)
    query = query.por_responsavel(params[:responsavel]) if params.key?(:responsavel)
    query
  end
end
