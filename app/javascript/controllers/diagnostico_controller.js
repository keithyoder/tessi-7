import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Update conexao_id when customer has multiple contracts
  selecionarConexao(event) {
    const conexaoId = event.target.value

    const campo = document.getElementById('campo-conexao-id')
    if (campo) campo.value = conexaoId

    document.querySelectorAll('[id^="painel-erp-"]').forEach(el => {
      el.style.display = 'none'
    })

    const painel = document.getElementById(`painel-erp-${conexaoId}`)
    if (painel) painel.style.display = ''

    document.querySelectorAll('[name="motivo"]').forEach(el => el.checked = false)
    document.getElementById('chat-container').innerHTML = `
      <div class="card">
        <div class="card-body text-center text-muted py-5">
          <p>Selecione o motivo do contato para iniciar o diagnóstico.</p>
        </div>
      </div>
    `
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

  limpar(event) {
    document.getElementById('resultado-busca').innerHTML = ''
    document.getElementById('chat-container').innerHTML = `
      <div class="card">
        <div class="card-body text-center text-muted py-5">
          <p>Busque um CPF e selecione o motivo do contato para iniciar o diagnóstico.</p>
        </div>
      </div>
    `
  }
}