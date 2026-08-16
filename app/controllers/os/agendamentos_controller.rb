# frozen_string_literal: true

class Os::AgendamentosController < ApplicationController # rubocop:disable Style/ClassAndModuleChildren
  skip_authorization_check

  def show
    @data = parse_data

    @os_do_dia = Os
      .com_endereco_carregado
      .includes(:classificacao, :tecnico_1, :tecnico_2)
      .where(agendado_em: @data.all_day)
      .order(:tecnico_1_id, :fechamento, :agendado_em, :id)

    @concluidas, @pendentes = @os_do_dia.partition { |os| os.fechamento.present? }

    respond_to do |format|
      format.html
      format.text { @grupos = agrupar_por_tecnico(@pendentes) }
    end
  end

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

    redirect_to agendamento_dia_os_index_path(data: agendado_em), notice: t('.notice')
  end

  private

  def agendamento_params
    params.require(:agendamento).permit(:agendado_em, :tecnico_1_id, :tecnico_2_id, os_ids: [])
  end

  def parse_data
    params[:data].present? ? Date.parse(params[:data]) : Date.current
  rescue ArgumentError
    Date.current
  end

  def agrupar_por_tecnico(lista)
    lista
      .group_by { |os| [os.tecnico_1_id, os.tecnico_2_id] }
      .map do |_ids, grupo|
        {
          tecnicos: [grupo.first.tecnico_1&.primeiro_nome, grupo.first.tecnico_2&.primeiro_nome].compact.join(' / '),
          municipio: municipio_predominante(grupo),
          os_list: grupo
        }
      end
  end

  def municipio_predominante(lista)
    lista.filter_map { |os| os.pessoa&.cidade&.nome }
      .tally.max_by { |_nome, count| count }&.first || 'Município desconhecido'
  end
end
