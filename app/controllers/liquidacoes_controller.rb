# frozen_string_literal: true

class LiquidacoesController < ApplicationController
  load_and_authorize_resource :fatura, through: :liquidacoes

  def index
    if params.key?(:mes)
      show_monthly_breakdown
    elsif params.key?(:ano)
      show_yearly_breakdown
    else
      show_daily_breakdown
    end
  end

  def show
    @liquidacoes = Fatura.includes(%i[contrato pessoa])
      .where('liquidacao = ?', params[:id])
    @liquidacoes = @liquidacoes.where('meio_liquidacao = ?', params[:meio]) if params.key?(:meio)
    @liquidacoes = @liquidacoes.page(params[:page])
  end

  private

  # Mostra liquidações agregadas por dia
  def show_daily_breakdown
    @liquidacoes = base_liquidacoes_query
      .select('liquidacao as data')
      .group(:liquidacao)
      .order(liquidacao: :desc)
      .page(params[:page])

    @chart = daily_chart_data
    @statistics = daily_statistics
  end

  # Mostra liquidações agregadas por mês de um ano específico
  def show_monthly_breakdown
    ano = params[:ano].to_i

    @liquidacoes = base_liquidacoes_query
      .select(Arel.sql('extract(month from liquidacao)::int as mes'))
      .where('extract(year from liquidacao) = ?', ano)
      .group(Arel.sql('extract(month from liquidacao)'))
      .order(:mes)
      .page(params[:page])

    @chart = monthly_chart_data(ano)
    @statistics = monthly_statistics(ano)
    @ano = ano
  end

  # Mostra liquidações agregadas por ano
  def show_yearly_breakdown
    @liquidacoes = base_liquidacoes_query
      .select(Arel.sql('extract(year from liquidacao)::int as ano'))
      .group(Arel.sql('extract(year from liquidacao)'))
      .order(:ano)
      .page(params[:page])

    @chart = yearly_chart_data
    @statistics = yearly_statistics
  end

  # Base query para todas as agregações
  def base_liquidacoes_query
    Fatura.select('count(*) as liquidacoes, sum(valor_liquidacao) as valor')
      .where.not(liquidacao: nil)
  end

  # Dados do gráfico para visualização diária (últimos 30 dias)
  def daily_chart_data
    Fatura.where(liquidacao: 30.days.ago.to_date..Date.current)
      .group(:liquidacao)
      .order(:liquidacao)
      .sum(:valor_liquidacao)
  end

  # Dados do gráfico para visualização mensal
  def monthly_chart_data(ano)
    Fatura.where('extract(year from liquidacao) = ?', ano)
      .group('extract(month from liquidacao)')
      .sum(:valor_liquidacao)
  end

  # Dados do gráfico para visualização anual
  def yearly_chart_data
    Fatura.where.not(liquidacao: nil)
      .group(Arel.sql('extract(year from liquidacao)'))
      .order(Arel.sql('extract(year from liquidacao)'))
      .sum(:valor_liquidacao)
  end

  # Estatísticas diárias (últimos 30 dias)
  def daily_statistics
    last_30_days = Fatura.where(liquidacao: 30.days.ago.to_date..Date.current)

    {
      total_recebido: last_30_days.sum(:valor_liquidacao),
      total_pagamentos: last_30_days.count,
      media_diaria: last_30_days.sum(:valor_liquidacao) / 30.0,
      dias_com_pagamento: last_30_days.select(:liquidacao).distinct.count
    }
  end

  # Estatísticas mensais com comparação à média histórica
  def monthly_statistics(ano)
    mes_atual = Date.current.month
    mes_selecionado = params[:mes]&.to_i || mes_atual
    inicio_mes = Date.new(ano, mes_selecionado, 1)
    fim_mes = inicio_mes.end_of_month

    # Limitar até hoje se for o mês atual
    fim_mes = [fim_mes, Date.current].min if ano == Date.current.year && mes_selecionado == mes_atual
    dia_atual_do_mes = fim_mes.day

    # Valores do mês atual (até hoje se for mês corrente)
    faturas_mes = Fatura.where(liquidacao: inicio_mes..fim_mes)
    total_mes = faturas_mes.sum(:valor_liquidacao)
    total_pagamentos_mes = faturas_mes.count

    # Cálculo da média histórica por dia do mês
    # Pega últimos 12 meses COMPLETOS (exclui mês atual se parcial)
    data_inicio_historico = 13.months.ago.beginning_of_month
    data_fim_historico = 1.month.ago.end_of_month

    # Agrupa por dia do mês (1-31) e calcula média de cada dia
    # Para cada dia: soma TODAS as faturas daquele dia e divide pelo número de meses
    historico_por_dia = Fatura
      .where(liquidacao: data_inicio_historico..data_fim_historico)
      .group(Arel.sql('EXTRACT(day FROM liquidacao)'))
      .select(
        Arel.sql('EXTRACT(day FROM liquidacao)::int as dia_do_mes'),
        Arel.sql('SUM(valor_liquidacao) as total_dia'),
        Arel.sql("COUNT(DISTINCT DATE_TRUNC('month', liquidacao)) as meses_count")
      )

    # Converte para hash para fácil acesso
    # Divide pelo número de meses que tiveram aquele dia
    # (importante: dia 31 só existe em alguns meses)
    medias_historicas = {}
    historico_por_dia.each do |registro|
      meses = registro.meses_count.to_f
      medias_historicas[registro.dia_do_mes] = meses > 0 ? (registro.total_dia.to_f / meses) : 0
    end

    # Soma as médias históricas apenas para os dias já decorridos no mês
    # Exemplo: Se hoje é dia 15, soma médias dos dias 1 a 15
    media_historica_acumulada = (1..dia_atual_do_mes).sum do |dia|
      medias_historicas[dia] || 0
    end

    projecao_mes = total_mes

    # Parte 2: Soma as médias históricas para os dias que faltam
    # Se hoje é dia 15, soma as médias dos dias 16 até o fim do mês (28, 29, 30 ou 31)
    ((dia_atual_do_mes + 1)..31).each do |dia|
      projecao_mes += medias_historicas[dia] || 0
    end

    # Performance: quanto estamos acima/abaixo da média
    diferenca_valor = total_mes - media_historica_acumulada
    diferenca_percentual = if media_historica_acumulada > 0
                             (diferenca_valor / media_historica_acumulada * 100)
                           else
                             0
                           end

    # Média diária do mês atual (para exibição)
    media_diaria_mes = dia_atual_do_mes > 0 ? total_mes / dia_atual_do_mes : 0

    # Média diária histórica (para exibição)
    media_diaria_historica = dia_atual_do_mes > 0 ? media_historica_acumulada / dia_atual_do_mes : 0

    {
      total_mes: total_mes,
      total_pagamentos_mes: total_pagamentos_mes,
      dias_decorridos: dia_atual_do_mes,
      media_diaria_mes: media_diaria_mes,
      media_diaria_historica: media_diaria_historica,
      media_historica_acumulada: media_historica_acumulada, # Total esperado até hoje
      projecao_mes: projecao_mes,
      diferenca_valor: diferenca_valor,
      diferenca_percentual: diferenca_percentual,
      performance: diferenca_percentual >= 0 ? :acima : :abaixo,
      medias_por_dia: medias_historicas # Para debug ou gráficos futuros
    }
  end

  # Estatísticas anuais
  def yearly_statistics
    ano_atual = Date.current.year
    faturas_ano = Fatura.where('extract(year from liquidacao) = ?', ano_atual)

    {
      total_ano: faturas_ano.sum(:valor_liquidacao),
      total_pagamentos_ano: faturas_ano.count,
      media_mensal: faturas_ano.sum(:valor_liquidacao) / Date.current.month.to_f
    }
  end

  def liquidacoes_params
    params.permit(:mes, :ano, :meio, :page)
  end
end
