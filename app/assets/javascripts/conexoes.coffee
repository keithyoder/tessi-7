# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

success = (pos) ->
  crd = pos.coords
  $('#conexao_latitude').val crd.latitude
  $('#conexao_longitude').val crd.longitude
  console.log 'Your current position is:'
  console.log 'Latitude : ${crd.latitude}'
  console.log 'Longitude: ${crd.longitude}'
  console.log 'More or less ${crd.accuracy} meters.'
  return

error = (err) ->
  console.warn 'ERROR(${err.code}): ${err.message}'
  return

window.getConexaoLocation = ->
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition success, error,
      {enableHighAccuracy: true,
      timeout: 60000,
      maximumAge: 0}
  return

window.carregarIPs = ->
  ponto = $("#conexao_ponto_id").val()
  $.ajax
    url: "/pontos/#{ponto}.json?ipv4"
    method: 'GET'
    dataType: 'json'
    error: (xhr, status, error) ->
      console.error 'AJAX Error: ' + status + error
      return
    success: (response) ->
      ips = response
      $("#conexao_ip").empty()
      for ip in ips
        $("#conexao_ip").append("<option>#{ip}</option>")
      return
  return

window.formatMAC = ->
  v = $("#conexao_mac").val().toUpperCase()
  last = v.substring(v.lastIndexOf(':') + 1, v.length)
  if last.length >= 2
    v = v + ':'
  if v.length > 17
    v = v.substring(0, 17)
  $("#conexao_mac").val(v)
  return

window.criar_mapa = ->
  latlng = new (google.maps.LatLng)($('#conexao_latitude').val(), $('#conexao_longitude').val())
  map = new (google.maps.Map)(document.getElementById('map_canvas'),
    zoom: 18
    center: latlng
  )

  myMarker = new (google.maps.Marker)(
    map: map
    position: latlng
    draggable: true
  )

  google.maps.event.addListener myMarker, 'dragend', (evt) ->
    $('#conexao_latitude').val evt.latLng.lat
    $('#conexao_longitude').val evt.latLng.lng
    return

  return