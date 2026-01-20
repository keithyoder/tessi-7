import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "liquidacao",
    "valorLiquidacao",
    "jurosRecebidos",
    "descontoConcedido",
    "data"
  ]

  connect() {
    if (!this.hasLiquidacaoTarget) return
  }

  calcularTotal(liquidacao) {
    const div = this.dataTarget
    const desconto = Number(div.dataset.desconto)
    const juros = Number(div.dataset.juros)
    const multa = Number(div.dataset.multa)
    const valor = Number(div.dataset.valor)
    const vencimento = div.dataset.vencimento

    const dias = Math.floor((Date.parse(liquidacao) - Date.parse(vencimento)) / (1000 * 3600 * 24))

    if (dias > 0) {
      return Math.round(((1 + multa) * valor + (juros / 30 * dias) * valor) * 10) / 10
    } else {
      return valor - desconto
    }
  }

  onLiquidacaoChange() {
    const data = this.liquidacaoTarget.value
    if (!data) return

    const valorOriginal = Number(this.dataTarget.dataset.valor)
    const valorLiquidacao = this.calcularTotal(data)

    this.jurosRecebidosTarget.value = valorLiquidacao > valorOriginal ? valorLiquidacao - valorOriginal : 0
    this.valorLiquidacaoTarget.value = valorLiquidacao
  }

  onValorChange() {
    const valorOriginal = Number(this.dataTarget.dataset.valor)
    const valorLiquidacao = Number(this.valorLiquidacaoTarget.value)

    if (valorLiquidacao > valorOriginal) {
      this.jurosRecebidosTarget.value = valorLiquidacao - valorOriginal
      this.descontoConcedidoTarget.value = 0
    } else if (valorLiquidacao < valorOriginal) {
      this.descontoConcedidoTarget.value = valorOriginal - valorLiquidacao
      this.jurosRecebidosTarget.value = 0
    } else {
      this.descontoConcedidoTarget.value = 0
      this.jurosRecebidosTarget.value = 0
    }
  }
}
