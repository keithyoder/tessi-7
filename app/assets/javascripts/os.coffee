# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

num2dot = (num) ->
  d = num % 256
  i = 3
  while i > 0
    num = Math.floor(num / 256)
    d = num % 256 + '.' + d
    i--
  d

jQuery ->
  carregarConexoes = ->
    pessoa = $("#os_pessoa_id").val()
    $.ajax
      url: "/pessoas/#{pessoa}.json?conexoes"
      method: 'GET'
      dataType: 'json'
      error: (xhr, status, error) ->
        console.error 'AJAX Error: ' + status + error
        return
      success: (response) ->
        conexoes = response
        conexao_salvo = $("#os_conexao_id").val()
        $("#os_conexao_id").empty()
        $("#os_conexao_id").append("<option value=''>--Escolher Conexão--</option>")
        for conexao in conexoes
          ip = num2dot(conexao.ip.addr)
          $("#os_conexao_id").append("<option value=#{conexao.id}>#{ip} - #{conexao.usuario}</option>")
        $("#os_conexao_id").val(conexao_salvo)
        return
    return

  $('#os_pessoa_id').change ->
    carregarConexoes()

  carregarConexoes()
