import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pessoa", "conexao", "tipo", "classificacao"]

  connect() {
    if (this.hasPessoaTarget && this.pessoaTarget.value) {
      this.carregarConexoes()
    }
    if (this.hasTipoTarget && this.tipoTarget.value) {
      this.carregarClassificacoes()
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
        const option = document.createElement('option')
        option.value = conexao.id
        option.textContent = `${conexao.ip} - ${conexao.usuario}`
        this.conexaoTarget.appendChild(option)
      }

      this.conexaoTarget.value = conexaoSalvo
    } catch (error) {
      console.error('AJAX Error:', error)
    }
  }

  async carregarClassificacoes() {
    const tipo = this.tipoTarget.value
    if (!tipo) return

    try {
      const response = await fetch(`/classificacoes.json?tipo=${encodeURIComponent(tipo)}`, {
        headers: { 'Accept': 'application/json' }
      })
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)

      const classificacoes = await response.json()
      const classificacaoSalva = this.classificacaoTarget.value

      this.classificacaoTarget.innerHTML = '<option value="">--Escolher Classificação--</option>'

      for (const classificacao of classificacoes) {
        const option = document.createElement('option')
        option.value = classificacao.id
        option.textContent = classificacao.nome
        this.classificacaoTarget.appendChild(option)
      }

      this.classificacaoTarget.value = classificacaoSalva
    } catch (error) {
      console.error('AJAX Error:', error)
    }
  }
}