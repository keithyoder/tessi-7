# frozen_string_literal: true

module Faturas
  class NfcomController < ApplicationController
    before_action :load_fatura

    def create
      authorize! :emitir_nfcom, @fatura

      return redirect_to @fatura, alert: t('.already_emitted') if @fatura.nfcom_notas.authorized.exists?

      Nfcom::Emitter.new.emitir(@fatura.id)

      redirect_to @fatura, notice: t('.success')
    rescue StandardError => e
      Rails.logger.error(e)
      redirect_to @fatura, alert: t('.error')
    end

    private

    def load_fatura
      @fatura = Fatura.find(params[:fatura_id])
    end
  end
end
