# frozen_string_literal: true

# Encontra um link do Google Maps em um texto qualquer (colado do WhatsApp,
# de uma descrição de OS, etc), resolve encurtadores (maps.app.goo.gl,
# goo.gl/maps) seguindo redirecionamentos, extrai latitude/longitude, e
# devolve o texto original com o link antigo substituído pelo canônico.
#
# Uso:
#   GoogleMapsCoordenadasService.call("Referência: https://maps.app.goo.gl/xyz")
#   # => { latitude: -8.356038, longitude: -36.6805342,
#   #      link: "https://www.google.com/maps?q=-8.356038,-36.6805342",
#   #      texto: "Referência: https://www.google.com/maps?q=-8.356038,-36.6805342" }
#
#   GoogleMapsCoordenadasService.call("sem link nenhum aqui")
#   # => nil
class GoogleMapsCoordenadasService
  LINK_REGEX = %r{https?://(?:maps\.app\.goo\.gl|goo\.gl/maps|maps\.google\.com|(?:www\.)?google\.com/maps)\S*}i
  MAX_REDIRECTS = 5

  def self.call(texto)
    new(texto).call
  end

  def initialize(texto)
    @texto = texto.to_s
  end

  def call
    link = extrair_link
    return nil if link.nil?

    lat, lng = coordenadas_de(link)
    return nil if lat.nil?

    novo_link = "https://www.google.com/maps?q=#{lat},#{lng}"

    { latitude: lat, longitude: lng, link: novo_link, texto: texto.sub(link, novo_link) }
  end

  private

  attr_reader :texto

  def extrair_link
    texto[LINK_REGEX]&.sub(/[.,;)\]]+\z/, '')
  end

  # Alguns links já vêm com as coordenadas no próprio texto (ex.: link
  # copiado da barra de endereço, ou um "?q=lat,lng" direto), então
  # tentamos extrair antes de gastar uma chamada HTTP resolvendo redirects.
  def coordenadas_de(link)
    lat, lng = coordenadas_da_url(link)
    return [lat, lng] if lat

    coordenadas_seguindo_redirecionamentos(link)
  end

  def coordenadas_seguindo_redirecionamentos(link)
    uri = URI.parse(link)

    MAX_REDIRECTS.times do
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPRedirection
        nova_uri = URI.parse(response['location'])
        uri = nova_uri.relative? ? uri.merge(nova_uri) : nova_uri
      else
        return coordenadas_da_url(uri.to_s)
      end
    end

    [nil, nil]
  rescue StandardError
    [nil, nil]
  end

  # Ordem de preferência: o pino real (!3d..!4d..) é mais preciso que o
  # centro do viewport (@lat,lng,zoom), que por sua vez é mais confiável
  # que um "?q=" cru (que também pode conter um endereço em texto).
  def coordenadas_da_url(url)
    match = url.match(/!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/) ||
            url.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/) ||
            url.match(/[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)/)

    return unless match

    [match[1].to_f, match[2].to_f]
  end
end
