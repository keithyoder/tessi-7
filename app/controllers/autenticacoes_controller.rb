# frozen_string_literal: true

class AutenticacoesController < ApplicationController
  include TurboFrameIndex

  escopavel_por :servidor_id, :ponto_id, :conexao_id

  authorize_resource

  def index
    @pagy, @autenticacoes = pagy(escopo.order(authdate: :desc))
  end

  private

  def escopo
    consulta = Autenticacao.joins(conexao: :ponto)

    consulta = consulta.where(pontos: { servidor_id: params[:servidor_id] }) if params[:servidor_id].present?
    consulta = consulta.where(pontos: { id: params[:ponto_id] }) if params[:ponto_id].present?
    consulta = consulta.where(conexoes: { id: params[:conexao_id] }) if params[:conexao_id].present?

    consulta
  end
end
