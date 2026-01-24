// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery

import { createPopper } from '@popperjs/core';

// Import Bootstrap and expose globally so data-bs-* attributes work
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap

import "chartkick/chart.js"

import "./faturas"
import "./fibra_caixas"
import "./os"
import "./phone-type-formatter.br"
import "./servidores"

// Initialize Bootstrap components after Turbo navigation
document.addEventListener('turbo:load', () => {
  // Initialize all tooltips
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
  
  // Initialize all popovers
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]')
  const popoverList = [...popoverTriggerList].map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl))
})

// Handle Turbo form submissions
document.addEventListener('turbo:submit-end', () => {
  // Close any open dropdowns after form submission
  const dropdowns = document.querySelectorAll('.dropdown-menu.show')
  dropdowns.forEach(dropdown => {
    const bsDropdown = bootstrap.Dropdown.getInstance(dropdown.previousElementSibling)
    if (bsDropdown) bsDropdown.hide()
  })
})