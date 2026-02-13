# frozen_string_literal: true

class PessoasController < ApplicationController
  before_action :set_pessoa, only: %i[show edit update destroy]
  before_action :set_scope, only: %i[index show new]
  load_and_authorize_resource
  # autocomplete :logradouro, :nome, full: true, display_value: :endereco

  # GET /pessoas
  # GET /pessoas.json
  def index
    @q = Pessoa.includes(:logradouro, :bairro, :cidade, :estado)
      .ransack(params[:q])
    @q.sorts = 'nome'
    @pessoas = @q.result.page params[:page]
  end

  # GET /pessoas/1
  # GET /pessoas/1.json
  def show
    @pessoa = Pessoa.find(params[:id])

    @params = (@params || {}).merge(pessoa_id: @pessoa)

    @conexoes = @pessoa
      .conexoes
      .includes(
        :pessoa,
        :plano,
        :ponto,
        :equipamento
      )
      .page(params[:conexoes_page])

    @conexoes_status = Conexao.status_conexoes(@conexoes)

    @contratos = @pessoa
      .contratos
      .order(:adesao)
      .page(params[:page])

    @os_q = @pessoa
      .os
      .includes(:pessoa, :classificacao)
      .ransack(params[:os_q])

    @os = @os_q.result.page(params[:page])

    @atendimentos_q = @pessoa
      .atendimentos
      .includes(:pessoa, :classificacao)
      .ransack(params[:atendimentos_q])

    @atendimentos = @atendimentos_q.result.page(params[:page])

    respond_to do |format|
      format.html
      format.json do
        params.key?(:conexoes) ? render(json: @conexoes) : render(:show)
      end
    end
  end

  # GET /pessoas/new
  def new
    @pessoa = Pessoa.new
  end

  # GET /pessoas/1/edit
  def edit; end

  # POST /pessoas
  # POST /pessoas.json
  def create
    @pessoa = Pessoa.new(pessoa_params)

    respond_to do |format|
      if @pessoa.save
        format.html { redirect_to @pessoa, notice: 'Pessoa criada com sucesso.' }
        format.json { render :show, status: :created, location: @pessoa }
      else
        format.html { render :new }
        format.json { render json: @pessoa.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /pessoas/1
  # PATCH/PUT /pessoas/1.json
  def update
    if @pessoa.update(pessoa_params)
      redirect_to @pessoa, notice: 'Pessoa foi atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /pessoas/1
  # DELETE /pessoas/1.json
  def destroy
    @pessoa.destroy
    respond_to do |format|
      format.html { redirect_to pessoas_url, notice: 'Pessoa was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_scope
    @params = params.permit(:page, q: [:nome_cont])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_pessoa
    @pessoa = Pessoa.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def pessoa_params
    params.require(:pessoa).permit(
      :nome, :tipo, :cpf, :cnpj, :rg, :ie, :nascimento, :logradouro_id, :numero,
      :complemento, :nomemae, :email, :telefone1, :telefone2, :rg_imagem
    )
  end
end
