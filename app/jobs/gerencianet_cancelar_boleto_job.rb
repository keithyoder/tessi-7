# frozen_string_literal: true

class GerencianetCancelarBoletoJob < ApplicationJob
  queue_as :default

  def perform(id_externo)
    params = {
      id: id_externo
    }

    GerencianetClient.cliente.cancelCharge(params: params)
  end
end
