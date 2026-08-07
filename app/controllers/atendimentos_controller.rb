# frozen_string_literal: true

class AtendimentosController < ApplicationController
  layout -> { turbo_frame_request? ? false : 'application' }
  before_action :set_atendimento, only: %i[show edit update destroy encerrar]
  authorize_resource

  # Parâmetros pelos quais um atendimento pode ser filtrado quando exibido
  # dentro da aba de outro recurso (Pessoa, Contrato, Conexao). A ordem só
  # importa para nomear o turbo-frame quando mais de um estiver presente.
  PARAMETROS_ESCOPO = %i[pessoa_id contrato_id conexao_id].freeze

  helper_method :id_frame, :incorporado?

  # GET /atendimentos
  def index
    @q = escopo_base.ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @search_params = @q.conditions.to_h { |c| [c.attributes.first, c.values.first] }

    @pagy, @atendimentos = pagy(@q.result, limit: 15)
  end

  # GET /atendimentos/1
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
    redirect_to @atendimento, notice: t('.notice')
  end

  # POST /atendimentos
  def create
    resultado = Atendimentos::CriarService.call(
      atendimento_params: atendimento_params.except(:detalhe_tipo, :detalhe_descricao),
      detalhe_tipo: atendimento_params[:detalhe_tipo],
      detalhe_descricao: atendimento_params[:detalhe_descricao],
      atendente: current_user,
      aberto_por: current_user
    )

    @atendimento = resultado[:atendimento]
    @detalhe = resultado[:detalhe]

    if resultado[:success]
      redirect_to @atendimento, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /atendimentos/1
  def update
    if @atendimento.update(atendimento_params.except(:detalhe_tipo, :detalhe_descricao))
      redirect_to @atendimento, notice: t('.notice')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /atendimentos/1
  def destroy
    @atendimento.destroy!
    redirect_to atendimentos_url, notice: t('.notice')
  end

  private

  def set_atendimento
    @atendimento = Atendimento.find(params[:id])
  end

  def atendimento_params
    params.require(:atendimento).permit(
      :pessoa_id, :classificacao_id, :responsavel_id, :fechamento, :contrato_id,
      :conexao_id, :fatura_id, :detalhe_tipo, :detalhe_descricao
    )
  end

  # Verdadeiro quando a index está sendo exibida como aba incorporada
  # (Pessoa, Contrato, Conexao) em vez da página avulsa /atendimentos.
  def incorporado?
    PARAMETROS_ESCOPO.any? { |parametro| params[parametro].present? }
  end

  # Id do turbo-frame da index. Na página avulsa usa um id fixo; quando
  # incorporada, gera um id compatível com o que as futuras abas vão usar,
  # por exemplo "pessoa_5_atendimentos" ou "contrato_12_atendimentos".
  def id_frame
    escopo = PARAMETROS_ESCOPO.find { |parametro| params[parametro].present? }
    return 'atendimentos_index' unless escopo

    "#{escopo.to_s.delete_suffix('_id')}_#{params[escopo]}_atendimentos"
  end

  def escopo_base
    consulta = Atendimento.includes(:pessoa, :classificacao, :responsavel, :aberto_por)
    PARAMETROS_ESCOPO.each do |parametro|
      consulta = consulta.where(parametro => params[parametro]) if params[parametro].present?
    end
    consulta = consulta.abertos unless params[:abertos] == '0'

    if params[:responsavel_id].present?
      consulta = consulta.por_responsavel(params[:responsavel_id])
    elsif params[:meus].present?
      consulta = consulta.por_responsavel(current_user)
    end

    consulta
  end
end
