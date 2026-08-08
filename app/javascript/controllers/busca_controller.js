// app/javascript/controllers/busca_controller.js
import { Controller } from "@hotwired/stimulus"

// Controller genérico de busca com autocomplete, reutilizável para
// qualquer recurso cujo endpoint responda em JSON como
// [{ id, text, ...outros_campos }] — ex: /pessoas.json?search=...,
// /logradouros.json?search=...
//
// Uso:
//   div[data-controller="busca" data-busca-url-value="/pessoas.json" \
//       data-busca-campos-meta-value='["cpf","endereco"]']
//     = f.hidden_field :pessoa_id, data: { busca_target: "id" }
//     input type="text" data-busca-target="input" \
//       data-action="input->busca#buscar"
//
// Dispara "busca:selecionada" no elemento (detail: { id, texto }) para
// controllers pai que precisem reagir à seleção.
export default class extends Controller {
  static targets = ["input", "id"]
  static values  = { url: String, camposMeta: { type: Array, default: [] } }

  connect() {
    this.boundEsconderLista = this.esconderLista.bind(this)
    document.addEventListener("click", this.boundEsconderLista)
  }

  disconnect() {
    document.removeEventListener("click", this.boundEsconderLista)
  }

  buscar() {
    clearTimeout(this.timeoutBusca)
    this.timeoutBusca = setTimeout(async () => {
      const termo = this.inputTarget.value.trim()
      if (termo.length < 2) {
        this.#limparLista()
        return
      }

      try {
        const resposta = await fetch(`${this.urlValue}?search=${encodeURIComponent(termo)}`, {
          headers: { Accept: "application/json" }
        })
        const resultados = await resposta.json()
        this.#renderizarLista(resultados)
      } catch (erro) {
        console.error("Erro ao buscar:", erro)
      }
    }, 300)
  }

  selecionar(event) {
    const { id, text: texto } = event.currentTarget.dataset
    this.idTarget.value = id
    this.inputTarget.value = texto
    this.#limparLista()
    this.dispatch("selecionada", { detail: { id, texto } })
  }

  esconderLista(event) {
    if (!this.element.contains(event.target)) this.#limparLista()
  }

  #renderizarLista(resultados) {
    this.#limparLista()
    if (!resultados.length) return

    const lista = document.createElement("ul")
    lista.className = "list-group position-absolute z-3 w-100 shadow-sm"
    lista.style.top = "100%"

    resultados.forEach(r => {
      const li = document.createElement("li")
      li.className = "list-group-item list-group-item-action py-1"
      li.dataset.id = r.id
      li.dataset.text = r.text
      li.dataset.action = "click->busca#selecionar"

      const principal = document.createElement("div")
      principal.className = "fw-semibold"
      principal.textContent = r.text
      li.appendChild(principal)

      const meta = this.camposMetaValue.map(campo => r[campo]).filter(Boolean).join(" · ")
      if (meta) {
        const metaEl = document.createElement("div")
        metaEl.className = "small text-muted"
        metaEl.textContent = meta
        li.appendChild(metaEl)
      }

      lista.appendChild(li)
    })

    this.inputTarget.closest(".position-relative").appendChild(lista)
  }

  #limparLista() {
    this.inputTarget.closest(".position-relative")?.querySelector("ul.list-group")?.remove()
  }
}