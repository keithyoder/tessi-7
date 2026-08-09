# frozen_string_literal: true

module Atendimentos
  class PainelController < ApplicationController
    skip_authorization_check
    before_action :set_usuario, only: :show

    # GET /atendimentos/painel
    def index
      return redirect_to atendimentos_painel_usuario_path(current_user) unless current_user.admin?

      @resumo_por_usuario = construir_resumo_por_usuario
      @resumo_por_categoria = construir_resumo_por_categoria
    end

    # GET /atendimentos/painel/:id
    def show
      autorizar_visualizacao!

      @stats = construir_stats_usuario(@usuario)
      @mais_antigos = Atendimento.abertos.where(responsavel_id: @usuario.id)
        .includes(:pessoa, :classificacao)
        .order(created_at: :asc)
        .limit(15)
    end

    private

    def set_usuario
      @usuario = User.find(params[:id])
    end

    def autorizar_visualizacao!
      return if current_user.admin? || current_user.id == @usuario.id

      raise CanCan::AccessDenied
    end

    # Versão em lote usada pelo index: evita N+1 fazendo 4 consultas no
    # total (3 contagens agrupadas + 1 carga dos abertos), em vez de
    # 5 consultas por usuário.
    def construir_resumo_por_usuario
      hoje = Date.current.all_day
      semana = Date.current.all_week

      abertos_hoje_por_usuario = Atendimento.where(created_at: hoje).group(:aberto_por_id).count
      abertos_semana_por_usuario = Atendimento.where(created_at: semana).group(:aberto_por_id).count
      fechados_hoje_por_usuario = Atendimento.where(fechamento: hoje).group(:responsavel_id).count
      abertos_por_responsavel = Atendimento.abertos.order(created_at: :asc).group_by(&:responsavel_id)

      User.order(:primeiro_nome).map do |usuario|
        abertos_do_usuario = abertos_por_responsavel[usuario.id] || []

        {
          usuario: usuario,
          abertos_hoje: abertos_hoje_por_usuario[usuario.id] || 0,
          abertos_semana: abertos_semana_por_usuario[usuario.id] || 0,
          total_abertos: abertos_do_usuario.size,
          fechados_hoje: fechados_hoje_por_usuario[usuario.id] || 0,
          mais_antigo: abertos_do_usuario.first
        }
      end
    end

    # Versão individual usada pelo show: um único usuário, então 5
    # consultas simples são aceitáveis aqui.
    def construir_stats_usuario(usuario)
      hoje = Date.current.all_day
      semana = Date.current.all_week
      abertos_do_usuario = Atendimento.abertos.where(responsavel_id: usuario.id)

      {
        abertos_hoje: Atendimento.where(aberto_por_id: usuario.id, created_at: hoje).count,
        abertos_semana: Atendimento.where(aberto_por_id: usuario.id, created_at: semana).count,
        total_abertos: abertos_do_usuario.count,
        fechados_hoje: Atendimento.where(responsavel_id: usuario.id, fechamento: hoje).count,
        mais_antigo: abertos_do_usuario.order(created_at: :asc).first
      }
    end

    def construir_resumo_por_categoria
      contagem_por_classificacao = Atendimento.abertos.group(:classificacao_id).count

      Classificacao.atendimentos
        .where(id: contagem_por_classificacao.keys)
        .order(:nome)
        .map do |classificacao|
        { classificacao: classificacao,
          total_abertos: contagem_por_classificacao[classificacao.id] }
      end
    end
  end
end
