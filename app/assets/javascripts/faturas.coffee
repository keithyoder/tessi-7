# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

calcular_total =(liquidacao) ->
  div = $('#fatura-data')
  desconto = div.data('desconto')
  juros = div.data('juros')
  multa = div.data('multa')
  valor = div.data('valor')
  vencimento = div.data('vencimento')
  dias = Math.floor((Date.parse(liquidacao) - Date.parse(vencimento)) / (1000 * 3600 * 24));

  #dias = Math.floor((liquidacao.getTime()-vencimento.getTime()) / (1000 * 3600 * 24))
  if dias > 0
    Math.round(((1 + multa) * valor + (juros / 30 * dias) * valor) * 10)/10
  else
    valor - desconto

$(document).ready ->
  $('#fatura_liquidacao').datepicker(
    uiLibrary: 'bootstrap4'
    format: 'dd/mm/yyyy'
    locale: 'pt-BR'
    maxDate: '+1d').on 'change', (e) ->
      valor_original = $('#fatura-data').data('valor')
      valor_liquidacao = calcular_total(
        $(this).datepicker('getDate')
      )
      if valor_liquidacao > valor_original
        $('#fatura_juros_recebidos').val valor_liquidacao - valor_original 
      $('#fatura_valor_liquidacao').val(
        calcular_total(
          $(this).datepicker('getDate')
        )
      )
  $('#fatura_valor_liquidacao').on 'change', (e) ->
    valor_original = $('#fatura-data').data('valor')
    valor_liquidacao = calcular_total(
      $(this).datepicker('getDate')
    )
    if $('#fatura_valor_liquidacao').val() > valor_original
      $('#fatura_juros_recebidos').val $('#fatura_valor_liquidacao').val() - valor_original 
      $('#fatura_desconto_concedido').val 0
    if $('#fatura_valor_liquidacao').val() < valor_original
      $('#fatura_desconto_concedido').val valor_original - $('#fatura_valor_liquidacao').val()
      $('#fatura_juros_recebidos').val 0
