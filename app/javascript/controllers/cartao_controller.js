import { Controller } from "@hotwired/stimulus"
import EfiJs from "payment-token-efi"

export default class extends Controller {
  static targets = [
    "cartaoCredito", "cartaoVencimentoMes", "cartaoVencimentoAno", "cartaoCvv",
    "token", "cartaoParcial",
    "dadosCartao", "dadosToken", "gerarTokenButton", "salvarButton"
  ]

  static values = {
    account: String,
    environment: String
  }

  async gerarToken(event) {
    event.preventDefault()

    try {
      const result = await EfiJs.CreditCard
        .setAccount(this.accountValue)
        .setEnvironment(this.environmentValue)
        .setCreditCardData({
          brand: await this.verifyBrand(),
          number: this.cartaoCreditoTarget.value,
          cvv: this.cartaoCvvTarget.value,
          expirationMonth: this.cartaoVencimentoMesTarget.value,
          expirationYear: this.cartaoVencimentoAnoTarget.value,
          reuse: false
        })
        .getPaymentToken()

      this.tokenTarget.value = result.payment_token
      this.cartaoParcialTarget.value = result.card_mask
      this.dadosCartaoTarget.classList.add("d-none")
      this.dadosTokenTarget.classList.remove("d-none")
      this.gerarTokenButtonTarget.classList.add("d-none")
      this.salvarButtonTarget.classList.remove("d-none")
    } catch (error) {
      console.error(`Código: ${error.code}, Nome: ${error.error}, Mensagem: ${error.error_description}`)
    }
  }

  async verifyBrand() {
    return await EfiJs.CreditCard
      .setCardNumber(this.cartaoCreditoTarget.value)
      .verifyCardBrand()
  }
}