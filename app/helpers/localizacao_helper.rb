# frozen_string_literal: true

module LocalizacaoHelper
  # Coordenadas padrão (Pesqueira) usadas quando o registro ainda não tem localização
  LOCALIZACAO_LAT_PADRAO = -8.3594
  LOCALIZACAO_LNG_PADRAO = -36.9608

  # Centro do mapa para qualquer registro com latitude/longitude (Conexao, Ponto, Servidor, FibraCaixa)
  def localizacao_map_center(registro)
    {
      lat: registro.latitude || LOCALIZACAO_LAT_PADRAO,
      lng: registro.longitude || LOCALIZACAO_LNG_PADRAO,
      zoom: registro.latitude.present? ? 18 : 13
    }
  end

  # Marcador único e arrastável para o registro, se ele já tiver coordenadas
  def localizacao_map_markers(registro, titulo:)
    return [] if registro.latitude.blank? || registro.longitude.blank?

    [{
      lat: registro.latitude,
      lng: registro.longitude,
      title: titulo,
      color: '#007bff',
      draggable: true,
      id: registro.id
    }]
  end
end
