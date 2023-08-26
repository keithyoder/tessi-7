# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

success = (pos) ->
  crd = pos.coords
  $('#fibra_caixa_latitude').val crd.latitude
  $('#fibra_caixa_longitude').val crd.longitude
  console.log 'Your current position is:'
  console.log 'Latitude : #{crd.latitude}'
  console.log 'Longitude: #{crd.longitude}'
  console.log 'More or less #{crd.accuracy} meters.'
  return

error = (err) ->
  console.warn 'ERROR(${err.code}): ${err.message}'
  return

window.getLocation = ->
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition success, error,
      {enableHighAccuracy: true,
      timeout: 60000,
      maximumAge: 10}
  return
