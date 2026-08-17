// app/javascript/controllers/enlace_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tecnologia", "wrapperCanal", "wrapperFibraCor"]

  connect() {
    this.alternar()
  }

  alternar() {
    const ehRadio = this.tecnologiaTarget.value === "Radio"
    this.wrapperCanalTarget.classList.toggle("d-none", !ehRadio)
    this.wrapperFibraCorTarget.classList.toggle("d-none", ehRadio)
  }
}