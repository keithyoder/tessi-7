# frozen_string_literal: true

class AtendimentoDetalhesController < ApplicationController
  before_action :set_atendimento_detalhe, only: %i[show]
  before_action :set_atendimento, only: %i[new create]
  load_and_authorize_resource

  # GET /atendimento_detalhes/1
  def show; end

  # GET /atendimento_detalhes/new
  def new
    @atendimento_detalhe = @atendimento.detalhes.build(atendente: current_user)
  end

  # POST /atendimento_detalhes
  def create
    @atendimento_detalhe = AtendimentoDetalhe.new(atendimento_detalhe_params)

    if @atendimento_detalhe.save
      redirect_to @atendimento_detalhe.atendimento, notice: t('.notice')
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_atendimento_detalhe
    @atendimento_detalhe = AtendimentoDetalhe.find(params[:id])
  end

  def set_atendimento
    @atendimento = Atendimento.find(params[:atendimento_id])
  end

  def atendimento_detalhe_params
    params.require(:atendimento_detalhe).permit(:atendimento_id, :tipo, :atendente_id, :descricao)
  end
end
