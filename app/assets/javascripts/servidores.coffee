# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

int2ip = (ipInt) ->
  (ipInt >>> 24) + '.' + (ipInt >> 16 & 255) + '.' + (ipInt >> 8 & 255) + '.' + (ipInt & 255)

getBounds = (conectadas, desconectadas) ->
  bounds = new google.maps.LatLngBounds()
  for conexao in conectadas
    position = new google.maps.LatLng(
      parseFloat(conexao.latitude),
      parseFloat(conexao.longitude)
    )
    bounds.extend(position)
  for conexao in desconectadas
    position = new google.maps.LatLng(
      parseFloat(conexao.latitude),
      parseFloat(conexao.longitude)
    )
    bounds.extend(position)
  return bounds

infoWindow = (conexao) ->
  if conexao.logradouro_id == null
    endereco = "#{conexao.logradouro_pessoa.nome}, #{conexao.pessoa.numero} - #{conexao.bairro.nome}"
  else
    endereco = "#{conexao.logradouro.nome}, #{conexao.numero} - #{conexao.bairro.nome}"

  infowindow = new google.maps.InfoWindow({
    content: "<h4><a href=/conexoes/#{conexao.id}>#{conexao.pessoa.nome}</a></h4>" +
    "<div id='bodyContent'>#{endereco}<br>"+
    "#{conexao.ponto.nome} - #{int2ip(conexao.ip.addr)}</div>"
  })

criarMarker = (map, conexao, conectada) ->
  position =
    lat: parseFloat(conexao.latitude)
    lng: parseFloat(conexao.longitude)
  if conectada
    label = ''
  else
    label = 'D'

  marker = new (google.maps.Marker)(
    position: position
    map: map
    label: label
  )
  marker.addListener 'click', () =>
    infoWindow(conexao).open(map, marker)

window.initMap = ->
  conectadas = $('#map').data 'conectadas'
  desconectadas = $('#map').data 'desconectadas'
  map = new (google.maps.Map)(document.getElementById('map'))
  map.fitBounds(getBounds(conectadas, desconectadas))
  for conexao in conectadas
    criarMarker(map, conexao, true)
  for conexao in desconectadas
    criarMarker(map, conexao, false)
  return
