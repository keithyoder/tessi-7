# frozen_string_literal: true

module FibraCaixasHelper
  def markers
    markers = []
    pontos = []
    @fibra_caixa.conexoes.where.not(latitude: nil, longitude: nil).each do |c|
      pontos.append([c.longitude, c.latitude])
      markers.append("markers=label:#{c.porta}|#{c.latitude},#{c.longitude}")
    end
    if @fibra_caixa.latitude && @fibra_caixa.longitude
      markers.append ["markers=color:blue%7Clabel:C|#{@fibra_caixa.latitude},#{@fibra_caixa.longitude}"]
    end
    if markers.length > 0
      "#{calculate_zoom(pontos)}#{markers.join('&')}"
    else
      "18#{markers.join('&')}"
    end
  end

  def calculate_zoom(pontos)
    distance = box_size(pontos)
    if distance < 100
      "zoom=19&"
    elsif distance < 200
      "zoom=18&"
    else
      ""
    end
  end

  def box_size(points)
    # calculate the distance between the corner points of the bounding box
    # that contains all the points
    lat = points.map { |point| point[1] }
    lng = points.map { |point| point[0] }
    haversine_distance(
      [lat.min, lng.min],
      [lat.max, lng.max]
    )
  end

  def haversine_distance(geo_a, geo_b)
    # Get latitude and longitude
    lat1, lon1 = geo_a
    lat2, lon2 = geo_b

    # Calculate radial arcs for latitude and longitude
    d_lat = (lat2 - lat1) * Math::PI / 180
    d_lon = (lon2 - lon1) * Math::PI / 180

    a = Math.sin(d_lat / 2) *
        Math.sin(d_lat / 2) +
        Math.cos(lat1 * Math::PI / 180) *
        Math.cos(lat2 * Math::PI / 180) *
        Math.sin(d_lon / 2) * Math.sin(d_lon / 2)

    2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 6_378_000
  end
end
