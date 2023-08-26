# frozen_string_literal: true

class AtendimentosController < ApplicationController
  before_action :set_atendimento, only: %i[show edit update destroy encerrar]
  before_action :set_scope, only: %i[index show new encerrar]
  load_and_authorize_resource

  # GET /atendimentos or /atendimentos.json
  def index
    atendimento = Atendimento
    atendimento = atendimento.abertos if params.key?(:abertos)
    atendimento = atendimento.fechados if params.key?(:fechados)
    atendimento = atendimento.por_responsavel(current_user) if params.key?(:meus)
    atendimento = atendimento.por_responsavel(params[:responsavel]) if params.key?(:responsavel)
    @q = atendimento.ransack(params[:q])
    @q.sorts = 'created_at'
    @atendimentos = @q.result.page params[:page]
    respond_to do |format|
      format.html
    end
  end

  # GET /atendimentos/1 or /atendimentos/1.json
  def show; end

  # GET /atendimentos/new
  def new
    @atendimento = Atendimento.new
    @atendimento.pessoa_id = params[:pessoa_id] if params.key?(:pessoa_id)
    @atendimento.responsavel = current_user
    @detalhe = AtendimentoDetalhe.new atendimento: @atendimento
  end

  # GET /atendimentos/1/edit
  def edit; end

  def encerrar
    respond_to do |format|
      if @atendimento.update!(fechamento: DateTime.now)
        format.html { redirect_to @atendimento, notice: 'Atendimento encerrado com sucesso.' }
        format.json { render :show, status: :created, location: @atendimento }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @atendimento.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /atendimentos or /atendimentos.json
  def create
    puts detalhe_params
    @atendimento = Atendimento.new(atendimento_params)
    @detalhe = AtendimentoDetalhe.new(
      atendimento: @atendimento,
      atendente: current_user,
      tipo: AtendimentoDetalhe.tipos.key(atendimento_params[:detalhe_tipo].to_i),
      descricao: atendimento_params[:detalhe_descricao]
    )
    respond_to do |format|
      if @atendimento.save && @detalhe.save
        format.html { redirect_to @atendimento, notice: 'Atendimento criado com sucesso.' }
        format.json { render :show, status: :created, location: @atendimento }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @atendimento.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /atendimentos/1 or /atendimentos/1.json
  def update
    respond_to do |format|
      if @atendimento.update(atendimento_params)
        format.html { redirect_to @atendimento, notice: 'Atendimento was successfully updated.' }
        format.json { render :show, status: :ok, location: @atendimento }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @atendimento.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /atendimentos/1 or /atendimentos/1.json
  def destroy
    @atendimento.destroy
    respond_to do |format|
      format.html { redirect_to atendimentos_url, notice: 'Atendimento was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_atendimento
    @atendimento = Atendimento.find(params[:id])
  end

  def set_scope
    @params = params.permit(:abertos, :fechados, :meus, :responsavel)
  end

  # Only allow a list of trusted parameters through.
  def atendimento_params
    params.require(:atendimento).permit(
      :pessoa_id, :classificacao_id, :responsavel_id, :fechamento, :contrato_id,
      :conexao_id, :fatura_id, :detalhe_tipo, :detalhe_descricao
    )
  end

  def detalhe_params
    params.permit(:detalhe_tipo, :detalhe_descricao)
  end
end
