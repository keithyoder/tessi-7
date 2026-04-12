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
      redirect_to faturamento_root_path, alert: t('faturamento.dia.invalid_date')
    end

    def validar_data
      return if @data.between?(Date.new(2020, 1, 1), Date.current)

      redirect_to faturamento_root_path, alert: t('faturamento.dia.invalid_or_future_date')
    end

    def carregar_faturas
      Fatura
        .includes(contrato: %i[pessoa plano])
        .where(liquidacao: @data)
        .order('contratos.id')
        .page(params[:page])
        .per(50)
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
