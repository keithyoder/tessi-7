import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Update conexao_id when customer has multiple contracts
  selecionarContrato(event) {
    const campo = document.querySelector('#form-diagnostico [name="conexao_id"]')
    if (campo) campo.value = event.target.value
  }

  // Copy PIX to clipboard
  copiarPix(event) {
    event.preventDefault()
    const pix = event.currentTarget.dataset.pix
    navigator.clipboard.writeText(pix).then(() => {
      const btn      = event.currentTarget
      const original = btn.innerHTML
      btn.innerHTML  = '<small>Copiado!</small>'
      setTimeout(() => { btn.innerHTML = original }, 2000)
    })
  }

  // Append user message to history and submit chat form
  enviar(event) {
    event.preventDefault()

    const texto = document.getElementById('mensagem_texto').value.trim()
    if (!texto) return

    const campo    = document.querySelector('[name="mensagens"]')
    const mensagens = JSON.parse(campo.value || '[]')
    mensagens.push({ role: 'user', content: texto })
    campo.value = JSON.stringify(mensagens)

    document.getElementById('mensagem_texto').value = ''
    document.getElementById('form-chat').requestSubmit()
  }
}