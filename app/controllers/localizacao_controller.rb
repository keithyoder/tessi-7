# frozen_string_literal: true

class LocalizacaoController < ApplicationController
  # POST /localizacao/resolver_coordenadas
  #
  # Recebe um texto qualquer (link colado, mensagem do WhatsApp, endereço)
  # e tenta extrair coordenadas de um link do Google Maps nele, seguindo
  # redirecionamentos de encurtadores quando necessário.
  def resolver_coordenadas
    resultado = GoogleMapsCoordenadasService.call(params[:texto])

    if resultado
      render json: { latitude: resultado[:latitude], longitude: resultado[:longitude] }
    else
      render json: { erro: 'Não foi possível extrair coordenadas desse link' }, status: :unprocessable_content
    end
  end
end
