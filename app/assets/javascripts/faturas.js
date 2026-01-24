// Calculate total based on liquidation date
const calcularTotal = (liquidacao) => {
  const div = document.getElementById('fatura-data');
  if (!div) return 0;

  const desconto = parseFloat(div.dataset.desconto) || 0;
  const juros = parseFloat(div.dataset.juros) || 0;
  const multa = parseFloat(div.dataset.multa) || 0;
  const valor = parseFloat(div.dataset.valor) || 0;
  const vencimento = new Date(div.dataset.vencimento);

  const dias = Math.floor((new Date(liquidacao) - vencimento) / (1000 * 3600 * 24));

  if (dias > 0) {
    return Math.round(((1 + multa) * valor + (juros / 30 * dias) * valor) * 10) / 10;
  } else {
    return valor - desconto;
  }
};

// Wait for the DOM to load
document.addEventListener('DOMContentLoaded', () => {
  const liquidacaoInput = document.getElementById('fatura_liquidacao');
  const valorLiquidacaoInput = document.getElementById('fatura_valor_liquidacao');
  const jurosRecebidosInput = document.getElementById('fatura_juros_recebidos');
  const descontoConcedidoInput = document.getElementById('fatura_desconto_concedido');
  const divData = document.getElementById('fatura-data');

  if (!liquidacaoInput || !valorLiquidacaoInput || !divData) return;

  // Initialize datepicker (using Gijgo datepicker)
  $(liquidacaoInput).datepicker({
    uiLibrary: 'bootstrap4',
    format: 'dd/mm/yyyy',
    locale: 'pt-BR',
    maxDate: '+1d'
  }).on('change', function () {
    const valorOriginal = parseFloat(divData.dataset.valor) || 0;
    const valorLiquidacao = calcularTotal($(this).datepicker('getDate'));

    if (valorLiquidacao > valorOriginal && jurosRecebidosInput) {
      jurosRecebidosInput.value = valorLiquidacao - valorOriginal;
    }

    valorLiquidacaoInput.value = valorLiquidacao;
  });

  // Handle manual change on liquidacao value
  valorLiquidacaoInput.addEventListener('change', () => {
    const valorOriginal = parseFloat(divData.dataset.valor) || 0;
    const valorLiquidacao = parseFloat(valorLiquidacaoInput.value) || 0;

    if (valorLiquidacao > valorOriginal && jurosRecebidosInput && descontoConcedidoInput) {
      jurosRecebidosInput.value = valorLiquidacao - valorOriginal;
      descontoConcedidoInput.value = 0;
    }

    if (valorLiquidacao < valorOriginal && jurosRecebidosInput && descontoConcedidoInput) {
      descontoConcedidoInput.value = valorOriginal - valorLiquidacao;
      jurosRecebidosInput.value = 0;
    }
  });
});
