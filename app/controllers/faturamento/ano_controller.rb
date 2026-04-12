# frozen_string_literal: true

module Faturamento
  class AnoController < BaseController
    before_action :set_ano
    before_action :validar_ano

    def index
      @estatisticas = EstatisticasAno.new(ano: @ano).call
      @chart_data = build_chart_data
    end

    private

    def set_ano
      @ano = params[:ano]&.to_i || Date.current.year
    end

    def validar_ano
      return if @ano.between?(2020, Date.current.year + 1)

      redirect_to faturamento_root_path, alert: t('faturamento.ano.invalid_year')
    end

    def build_chart_data
      meses = @estatisticas[:meses]

      return { 'Real' => [], 'Esperado' => [] } if meses.empty?

      {
        'Real' => meses.map { |m| [m[:mes], m[:total_recebido]] },
        'Esperado' => meses.map { |m| [m[:mes], m[:total_esperado]] }
      }
    end
  end
end
