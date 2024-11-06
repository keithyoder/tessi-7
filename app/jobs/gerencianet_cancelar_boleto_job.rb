# frozen_string_literal: true

class GerencianetCancelarBoletoJob < ApplicationJob # rubocop:disable Style/Documentation
  queue_as :default

  def perform(id_externo)
    params = {
      id: id_externo
    }

    GerencianetClient.cliente.cancelCharge(params: params)
  end
end
