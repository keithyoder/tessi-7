# frozen_string_literal: true

class Os::AgendamentosController < ApplicationController # rubocop:disable Style/ClassAndModuleChildren
  skip_authorization_check

  def new
    resultado = Os::RoteirizacaoService.new.call
    @grupos = resultado[:grupos]
    @sem_coordenadas = resultado[:sem_coordenadas]
  end

  def create
    os_ids = Array(agendamento_params[:os_ids]).map(&:to_i)
    agendado_em = agendamento_params[:agendado_em]
    tecnico_1_id = agendamento_params[:tecnico_1_id].presence
    tecnico_2_id = agendamento_params[:tecnico_2_id].presence

    Os.where(id: os_ids).find_each do |os|
      authorize! :update, os

      ja_agendado = os.agendado_em.present?
      os.update!(
        agendado_em: agendado_em,
        tecnico_1_id: tecnico_1_id,
        tecnico_2_id: tecnico_2_id,
        vezes_reagendada: ja_agendado ? os.vezes_reagendada + 1 : os.vezes_reagendada
      )
    end

    redirect_to os_index_path, notice: t('.notice')
  end

  private

  def agendamento_params
    params.require(:agendamento).permit(:agendado_em, :tecnico_1_id, :tecnico_2_id, os_ids: [])
  end
end
