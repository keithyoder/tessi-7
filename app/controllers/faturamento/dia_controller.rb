# frozen_string_literal: true

module Faturamento
  class DiaController < BaseController
    before_action :set_data
    before_action :validar_data

    def index
      @estatisticas = EstatisticasDia.new(data: @data).call
      @faturas = carregar_faturas

      respond_to do |format|
        format.html
        format.pdf do
          render_pdf
        end
        format.csv do
          send_csv
        end
      end
    end

    private

    def set_data
      # Accepts date in format YYYY-MM-DD
      @data = Date.parse(params[:data])
      @ano = @data.year
      @mes = @data.month
    rescue ArgumentError
      redirect_to faturamento_root_path, alert: 'Data inválida'
    end

    def validar_data
      return if @data.between?(Date.new(2020, 1, 1), Date.current)

      redirect_to faturamento_root_path, alert: 'Data inválida ou futura'
    end

    def carregar_faturas
      # Eager load associations to avoid N+1
      Fatura
        .includes(contrato: %i[pessoa plano])
        .where(liquidacao: @data)
        .order('contratos.id')
        .page(params[:page])
        .per(50)
    end

    def render_pdf
      pdf_html = render_to_string(
        template: 'faturamento/dia/index',
        layout: 'print',
        formats: [:html]
      )

      send_data(
        WickedPdf.new.pdf_from_string(pdf_html),
        filename: "faturamento_#{@data}.pdf",
        type: 'application/pdf',
        disposition: 'inline'
      )
    end

    def send_csv
      csv_data = Fatura
        .includes(contrato: %i[pessoa plano])
        .where(liquidacao: @data)
        .order('contratos.id')
        .to_csv

      send_data(
        csv_data,
        filename: "faturas_#{@data}.csv",
        type: 'text/csv',
        disposition: 'attachment'
      )
    end
  end
end
