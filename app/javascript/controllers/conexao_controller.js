import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ponto", "ip", "ipv6", "caixa", "mac",
                    "logradouroInput", "logradouroId",
                    "pessoaInput", "pessoaId",
                    "tipo", "contrato", "contratoWrapper",
                    "caixaPortaWrapper"]
  static values  = { currentIp: String, currentIpv6: String, currentCaixaId: Number }

  connect() {
    this.boundHideDropdown = this.hideDropdown.bind(this)
    document.addEventListener("click", this.boundHideDropdown)
    this.tipoChanged()
    this.caixaPortaWrapperTarget.style.display = "none"

    // On edit, check existing ponto's tecnologia
    const pontoId = this.pontoTarget.value
    if (pontoId) this.pontoChanged()
  }

  disconnect() {
    document.removeEventListener("click", this.boundHideDropdown)
  }

  // ── Tipo ─────────────────────────────────────────────────────────────

  tipoChanged() {
    const cortesia = this.tipoTarget.value === "Cortesia"
    this.contratoWrapperTarget.style.display = cortesia ? "none" : ""
  }

  // ── Ponto ────────────────────────────────────────────────────────────

  async pontoChanged() {
    const pontoId = this.pontoTarget.value
    if (!pontoId) {
      this.caixaPortaWrapperTarget.style.display = "none"
      return
    }

    try {
      const resp = await fetch(`/pontos/${pontoId}.json`, {
        headers: { Accept: "application/json" }
      })
      const data = await resp.json()

      this.#repopulateSelect(this.ipTarget,   data.ipv4, this.currentIpValue)
      this.#repopulateSelect(this.ipv6Target, data.ipv6, this.currentIpv6Value)
      this.#repopulateCaixas(data.caixas)

      this.caixaPortaWrapperTarget.style.display = data.tecnologia === "Fibra" ? "" : "none"
    } catch(err) {
      console.error("Erro ao carregar dados do ponto:", err)
    }
  }

  // ── MAC ──────────────────────────────────────────────────────────────

  formatMAC() {
    const digits = this.macTarget.value.replace(/[^0-9a-fA-F]/g, "").toUpperCase().slice(0, 12)
    this.macTarget.value = digits.match(/.{1,2}/g)?.join(":") ?? digits
  }

  // ── Pessoa autocomplete ──────────────────────────────────────────────

  searchPessoa() {
    clearTimeout(this.pessoaTimeout)
    this.pessoaTimeout = setTimeout(async () => {
      const q = this.pessoaInputTarget.value.trim()
      if (q.length < 2) {
        this.#clearDropdown("pessoa")
        return
      }

      try {
        const resp = await fetch(`/pessoas.json?search=${encodeURIComponent(q)}`, {
          headers: { Accept: "application/json" }
        })
        const results = await resp.json()
        this.#renderPessoaDropdown(results)
      } catch(err) {
        console.error("Erro ao buscar pessoas:", err)
      }
    }, 300)
  }

  selectPessoa(event) {
    const { id, text } = event.currentTarget.dataset
    this.pessoaIdTarget.value    = id
    this.pessoaInputTarget.value = text
    this.#clearDropdown("pessoa")
  }

  // ── Logradouro autocomplete ──────────────────────────────────────────

  searchLogradouro() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(async () => {
      const q = this.logradouroInputTarget.value.trim()
      if (q.length < 2) {
        this.#clearDropdown("logradouro")
        return
      }

      try {
        const resp = await fetch(`/logradouros.json?search=${encodeURIComponent(q)}`, {
          headers: { Accept: "application/json" }
        })
        const results = await resp.json()
        this.#renderLogradouroDropdown(results)
      } catch(err) {
        console.error("Erro ao buscar logradouros:", err)
      }
    }, 300)
  }

  selectLogradouro(event) {
    const { id, text } = event.currentTarget.dataset
    this.logradouroIdTarget.value    = id
    this.logradouroInputTarget.value = text
    this.#clearDropdown("logradouro")
  }

  hideDropdown(event) {
    if (!this.element.contains(event.target)) {
      this.#clearDropdown("pessoa")
      this.#clearDropdown("logradouro")
    }
  }

  // ── Private ──────────────────────────────────────────────────────────

  #repopulateSelect(selectEl, options, currentVal) {
    const prev = currentVal || selectEl.value
    selectEl.innerHTML = ""
    if (prev && !options.includes(prev)) {
      const o = new Option(`${prev} (atual)`, prev)
      o.selected = true
      selectEl.add(o)
    }
    options.forEach(opt => {
      const o = new Option(opt, opt)
      if (opt === prev) o.selected = true
      selectEl.add(o)
    })
  }

  #repopulateCaixas(caixas) {
    const prev = this.currentCaixaIdValue || parseInt(this.caixaTarget.value)
    this.caixaTarget.innerHTML = '<option value="">— nenhuma —</option>'
    caixas.forEach(({ id, nome }) => {
      const o = new Option(nome, id)
      if (id === prev) o.selected = true
      this.caixaTarget.add(o)
    })
  }

  #renderPessoaDropdown(results) {
    this.#clearDropdown("pessoa")
    if (!results.length) return

    const list = document.createElement("ul")
    list.className = "list-group position-absolute z-3 w-100 shadow-sm"
    list.style.top = "100%"

    results.forEach(r => {
      const li = document.createElement("li")
      li.className = "list-group-item list-group-item-action py-1"
      li.dataset.id     = r.id
      li.dataset.text   = r.text
      li.dataset.action = "click->conexao#selectPessoa"

      const nome = document.createElement("div")
      nome.className = "fw-semibold"
      nome.textContent = r.text

      const meta = document.createElement("div")
      meta.className = "small text-muted"
      const parts = [r.cpf, r.endereco].filter(Boolean)
      meta.textContent = parts.join(" · ")

      li.appendChild(nome)
      li.appendChild(meta)
      list.appendChild(li)
    })

    const wrapper = this.pessoaInputTarget.closest(".position-relative")
    wrapper.appendChild(list)
  }

  #renderLogradouroDropdown(results) {
    this.#clearDropdown("logradouro")
    if (!results.length) return

    const list = document.createElement("ul")
    list.className = "list-group position-absolute z-3 w-100 shadow-sm"
    list.style.top = "100%"

    results.forEach(r => {
      const li = document.createElement("li")
      li.className = "list-group-item list-group-item-action py-1 small"
      li.textContent = r.text
      li.dataset.id     = r.id
      li.dataset.text   = r.text
      li.dataset.action = "click->conexao#selectLogradouro"
      list.appendChild(li)
    })

    const wrapper = this.logradouroInputTarget.closest(".position-relative")
    wrapper.appendChild(list)
  }

  #clearDropdown(type) {
    const target = type === "pessoa"
      ? this.pessoaInputTarget
      : this.logradouroInputTarget
    target.closest(".position-relative")?.querySelector("ul.list-group")?.remove()
  }
}