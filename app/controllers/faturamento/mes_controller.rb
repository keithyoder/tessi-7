# frozen_string_literal: true

module Faturamento
  class MesController < BaseController
    before_action :set_periodo
    before_action :validar_periodo

    def index
      @estatisticas = EstatisticasMes.new(ano: @ano, mes: @mes).call
      @chart_data = build_chart_data

      respond_to do |format|
        format.html
        format.pdf do
          render_pdf
        end
      end
    end

    private

    def set_periodo
      @ano = params[:ano].to_i
      @mes = params[:mes].to_i
      @data_inicio = Date.new(@ano, @mes, 1)
      @data_fim = @data_inicio.end_of_month
    end

    def validar_periodo
      return if (1..12).cover?(@mes) && @ano.between?(2020, Date.current.year + 1)

      redirect_to faturamento_root_path, alert: 'Período inválido'
    end

    def build_chart_data
      dias = @estatisticas[:dias]

      return { 'Real' => [], 'Esperado' => [] } if dias.empty?

      {
        'Real' => dias.map { |d| [d[:dia].to_s, d[:acumulado_real]] },
        'Esperado' => dias.map { |d| [d[:dia].to_s, d[:acumulado_esperado]] }
      }
    end

    def render_pdf
      pdf_html = render_to_string(
        template: 'faturamento/mes/index',
        layout: 'print',
        formats: [:html]
      )

      send_data(
        WickedPdf.new.pdf_from_string(pdf_html),
        filename: "faturamento_#{@ano}_#{@mes}.pdf",
        type: 'application/pdf',
        disposition: 'inline'
      )
    end
  end
end
