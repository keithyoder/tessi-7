// app/javascript/controllers/conexao_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ponto", "ip", "mac"]

  // Called automatically when the user changes the Ponto select
  carregarIPs() {
    const pontoId = this.pontoTarget.value
    if (!pontoId) return

    fetch(`/pontos/${pontoId}.json?ipv4`)
      .then((r) => r.json())
      .then((ips) => {
        // Clear and populate the IP select
        this.ipTarget.innerHTML = ""
        ips.forEach((ip) => {
          const option = document.createElement("option")
          option.textContent = ip
          this.ipTarget.appendChild(option)
        })
      })
      .catch((err) => console.error("Error fetching IPs:", err))
  }

  formatMAC() {
    let v = this.macTarget.value.toUpperCase()
    const last = v.substring(v.lastIndexOf(":") + 1)

    if (last.length >= 2) v += ":"
    if (v.length > 17) v = v.substring(0, 17)

    this.macTarget.value = v
  }
}
