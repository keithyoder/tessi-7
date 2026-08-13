// app/javascript/controllers/agendamento_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  permitirReagendar(event) {
    const row = event.target.closest("tr")
    const checkbox = row.querySelector('[data-agendamento-target="checkbox"]')
    checkbox.disabled = false
    event.target.remove()
  }
}