# frozen_string_literal: true

class GerencianetBaixarBoletoJob < ApplicationJob
  
  def perform(id_externo)
    params = {
      id: id_externo
    }
      
    GerencianetClient.cliente.settle_charge(params: params)
  end
end
  