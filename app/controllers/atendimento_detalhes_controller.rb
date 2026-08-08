# frozen_string_literal: true

class AtendimentoDetalhesController < ApplicationController
  before_action :set_atendimento, only: %i[create]
  load_and_authorize_resource

  # POST /atendimento_detalhes
  def create
    @atendimento_detalhe = @atendimento.detalhes.build(atendimento_detalhe_params)
    @atendimento_detalhe.atendente = current_user

    if @atendimento_detalhe.save
      redirect_to @atendimento_detalhe.atendimento, notice: t('.notice')
    else
      redirect_to @atendimento, alert: @atendimento_detalhe.errors.full_messages.to_sentence
    end
  end

  private

  def set_atendimento
    @atendimento = Atendimento.find(params[:atendimento_id])
  end

  def atendimento_detalhe_params
    params.require(:atendimento_detalhe).permit(:tipo, :descricao)
  end
end
