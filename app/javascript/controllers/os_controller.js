import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pessoa", "conexao"]

  connect() {
    if (this.hasPessoaTarget && this.pessoaTarget.value) {
      this.carregarConexoes()
    }
  }

  async carregarConexoes() {
    const pessoa = this.pessoaTarget.value
    if (!pessoa) return

    try {
      const response = await fetch(`/pessoas/${pessoa}.json?conexoes`, {
        headers: { 'Accept': 'application/json' }
      })
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)

      const conexoes = await response.json()
      const conexaoSalvo = this.conexaoTarget.value

      this.conexaoTarget.innerHTML = '<option value="">--Escolher Conexão--</option>'

      for (const conexao of conexoes) {
        const ip = this.num2dot(conexao.ip.addr)
        const option = document.createElement('option')
        option.value = conexao.id
        option.textContent = `${ip} - ${conexao.usuario}`
        this.conexaoTarget.appendChild(option)
      }

      this.conexaoTarget.value = conexaoSalvo
    } catch (error) {
      console.error('AJAX Error:', error)
    }
  }

  num2dot(num) {
    let d = num % 256
    let i = 3
    while (i > 0) {
      num = Math.floor(num / 256)
      d = (num % 256) + '.' + d
      i--
    }
    return d
  }
}