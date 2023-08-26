# frozen_string_literal: true

class GerencianetCriarBoletoJob < ApplicationJob
  
  def perform(fatura)
    GerencianetClient.criar_boleto(fatura)
  end
end
  