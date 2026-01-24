// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery

import * as bootstrap from "bootstrap"
import "chartkick/chart.js"

import "./conexao"
import "./faturas"
import "./fibra_caixas"
import "./os"
import "./phone-type-formatter.br"
import "./servidores"