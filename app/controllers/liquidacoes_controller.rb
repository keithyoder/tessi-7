# frozen_string_literal: true

class LiquidacoesController < ApplicationController
  load_and_authorize_resource :fatura, through: :liquidacoes

  def index # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @liquidacoes = Fatura.select('count(*) as liquidacoes, sum(valor_liquidacao) as valor')
                         .where.not(liquidacao: nil)
    if params.key?(:mes)
      @liquidacoes = @liquidacoes.select(Arel.sql('extract(month from liquidacao)::int as mes'))
                                 .where('extract(year from liquidacao) = ?', params[:ano])
                                 .group(Arel.sql('extract(month from liquidacao)'))
                                 .order(:mes)
      @chart = Fatura.where('extract(year from liquidacao) = ?', params[:ano])
                     .group('extract(month from liquidacao)')
                     .sum(:valor_liquidacao)
    elsif params.key?(:ano)
      @liquidacoes = @liquidacoes.select(Arel.sql('extract(year from liquidacao)::int as ano'))
                                 .group(Arel.sql('extract(year from liquidacao)'))
                                 .order(:ano)
      @chart = Fatura.where.not(liquidacao: nil)
                     .group(Arel.sql('extract(year from liquidacao)'))
                     .order(Arel.sql('extract(year from liquidacao)'))
                     .sum(:valor_liquidacao)
    else
      @liquidacoes = @liquidacoes.select('liquidacao as data').group(:liquidacao).order(liquidacao: :desc)
    end
    @liquidacoes.page params[:page]
  end

  def show
    @liquidacoes = Fatura.includes(%i[contrato pessoa]).where('liquidacao = ?', params[:id])
    @liquidacoes = @liquidacoes.where('meio_liquidacao = ?', params[:meio]) if params.key?(:meio)
    @liquidacoes = @liquidacoes.page params[:page]
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def liquidacoes_params
    params.permit(:mes, :ano)
  end
end
