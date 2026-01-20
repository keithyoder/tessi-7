# frozen_string_literal: true

class GerencianetBaixarBoletoJob < ApplicationJob
  
  def perform(id_externo)
    params = {
      id: id_externo
    }
      
    GerencianetClient.cliente.settleCharge(params: params)
  end
end
  