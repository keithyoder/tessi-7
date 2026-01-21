# frozen_string_literal: true

module Contratos
  class RenovacoesController < BaseController
    # POST /contratos/:contrato_id/renovacao
    def create
      authorize! :renovar, @contrato

      faturas_geradas = Contratos::RenovarService.new(
        contrato: @contrato,
        meses_por_fatura: renovacao_params[:meses_por_fatura]
      ).call

      if faturas_geradas.present?
        count = faturas_geradas.count
        notice = "#{count} #{'fatura'.pluralize(count)} gerada#{'s' if count > 1} com sucesso."
      else
        notice = 'Não há meses restantes para renovar o contrato.'
      end

      redirect_to @contrato, notice: notice
    rescue StandardError => e
      redirect_to @contrato, alert: "Erro ao renovar contrato: #{e.message}"
    end

    private

    def renovacao_params
      params.permit(:meses_por_fatura)
    end
  end
end
