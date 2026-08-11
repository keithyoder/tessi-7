import { Controller } from '@hotwired/stimulus'

// Uso: botão com data-controller="clipboard" data-clipboard-text-value="..."
// e data-action="clipboard#copy"
export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => this.showFeedback())
  }

  showFeedback() {
    const button = this.element
    const originalHtml = button.innerHTML

    button.innerHTML = '<i class="bi bi-check-lg"></i>'
    button.classList.replace('btn-outline-secondary', 'btn-success')

    setTimeout(() => {
      button.innerHTML = originalHtml
      button.classList.replace('btn-success', 'btn-outline-secondary')
    }, 1500)
  }
}