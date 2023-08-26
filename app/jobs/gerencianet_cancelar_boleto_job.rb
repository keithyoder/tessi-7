# frozen_string_literal: true

class GerencianetCancelarBoletoJob < ApplicationJob
  
  def perform(id_externo)
    params = {
      id: id_externo
    }
      
    GerencianetClient.cliente.cancel_charge(params: params)
  end
end
  