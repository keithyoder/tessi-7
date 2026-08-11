# frozen_string_literal: true

class Os::EncerramentosController < ApplicationController # rubocop:disable Style/ClassAndModuleChildren
  before_action :set_os

  # GET /os/:os_id/encerramento
  def show
    authorize! :update, @os
  end

  # PATCH /os/:os_id/encerramento
  def update
    authorize! :update, @os

    Os::EncerrarService.new(
      os: @os,
      resultado: encerramento_params[:resultado],
      encerramento: encerramento_params[:encerramento],
      tecnico_1_id: encerramento_params[:tecnico_1_id],
      tecnico_2_id: encerramento_params[:tecnico_2_id]
    ).call

    redirect_to @os, notice: t('.notice')
  rescue StandardError => e
    redirect_to os_encerramento_path(@os), alert: "Erro ao encerrar OS: #{e.message}"
  end

  private

  def set_os
    @os = ::Os.find(params[:os_id])
  end

  def encerramento_params
    params.require(:encerramento).permit(:resultado, :encerramento, :tecnico_1_id, :tecnico_2_id)
  end
end
