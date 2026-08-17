// app/javascript/controllers/extremidade_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tipo", "tipoHidden", "servidor", "ponto", "wrapperServidor", "wrapperPonto"]

  connect() {
    this.alternar()
  }

  alternar() {
    const tipo = this.tipoTarget.value
    this.tipoHiddenTarget.value = tipo

    const ehServidor = tipo === "Servidor"
    this.servidorTarget.disabled = !ehServidor
    this.pontoTarget.disabled = ehServidor
    this.wrapperServidorTarget.classList.toggle("d-none", !ehServidor)
    this.wrapperPontoTarget.classList.toggle("d-none", ehServidor)
  }
}