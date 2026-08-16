// app/javascript/controllers/geolocation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "map", "colar"]

  connect() {
    console.log("Geolocation controller connected")
    console.log("Has map target:", this.hasMapTarget)

    // Listen for marker-moved events from the map
    if (this.hasMapTarget) {
      this.boundMarkerMoved = this.onMarkerMoved.bind(this)
      this.mapTarget.addEventListener('marker-moved', this.boundMarkerMoved)
      console.log("Added marker-moved event listener to map")
    }
  }

  disconnect() {
    if (this.hasMapTarget && this.boundMarkerMoved) {
      this.mapTarget.removeEventListener('marker-moved', this.boundMarkerMoved)
      console.log("Removed marker-moved event listener")
    }
  }

  getLocation(event) {
    event.preventDefault()

    if (!navigator.geolocation) {
      alert("Geolocalização não é suportada pelo seu navegador")
      return
    }

    const button = event.currentTarget
    const originalText = button.innerHTML
    button.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Obtendo localização...'
    button.disabled = true

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude
        const lng = position.coords.longitude

        console.log("Got GPS position:", lat, lng)

        this.applyCoordinates(lat, lng)

        button.innerHTML = originalText
        button.disabled = false
      },
      (error) => {
        console.error("Geolocation error:", error)
        alert(`Erro ao obter localização: ${error.message}`)
        button.innerHTML = originalText
        button.disabled = false
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }

  onMarkerMoved(event) {
    console.log("🎯 Marker moved event received in geolocation controller:", event.detail)
    const { lat, lng } = event.detail
    this.updateCoordinates(lat, lng)
  }

  // Called on input in the "colar coordenada ou link" field
  parseInput(event) {
    const value = event.target.value.trim()
    if (!value) return

    // 1. Par de coordenadas cru: "lat, lng"
    const par = value.match(/^(-?\d{1,3}(?:\.\d+)?)[,\s]+(-?\d{1,3}(?:\.\d+)?)$/)
    if (par) {
      this.applyCoordinates(parseFloat(par[1]), parseFloat(par[2]))
      event.target.value = ""
      return
    }

    // 2. Link completo do Google Maps que já traz as coordenadas
    const extraido = this.extrairDeUrlMaps(value)
    if (extraido) {
      this.applyCoordinates(extraido.lat, extraido.lng)
      event.target.value = ""
      return
    }

    // 3. Parece uma URL mas sem coordenadas visíveis — provavelmente um
    // encurtador (maps.app.goo.gl/...). Pede pro servidor seguir o redirect.
    if (/^https?:\/\//i.test(value)) {
      this.resolverViaServidor(value, event.target)
    }
  }

  extrairDeUrlMaps(value) {
    let match = value.match(/!3d(-?\d{1,3}\.\d+)!4d(-?\d{1,3}\.\d+)/)
    if (match) return { lat: parseFloat(match[1]), lng: parseFloat(match[2]) }

    match = value.match(/@(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)/)
    if (match) return { lat: parseFloat(match[1]), lng: parseFloat(match[2]) }

    match = value.match(/[?&]q=(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)/)
    if (match) return { lat: parseFloat(match[1]), lng: parseFloat(match[2]) }

    return null
  }

  async resolverViaServidor(texto, input) {
    input.disabled = true

    try {
      const response = await fetch("/localizacao/resolver_coordenadas", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ texto })
      })

      const data = await response.json()

      if (response.ok && data.latitude && data.longitude) {
        this.applyCoordinates(parseFloat(data.latitude), parseFloat(data.longitude))
        input.value = ""
      } else {
        alert(data.erro || "Não foi possível extrair coordenadas desse link")
      }
    } catch (error) {
      console.error("Erro ao resolver link do Google Maps:", error)
      alert("Não foi possível resolver esse link")
    } finally {
      input.disabled = false
    }
  }

  // Ponto único de entrada para qualquer origem de coordenadas (GPS,
  // arrastar o pino, colar um par ou link): atualiza os campos, recentra
  // o mapa e garante que o pino apareça, mesmo em um registro novo que
  // ainda não tinha nenhum.
  applyCoordinates(lat, lng) {
    this.updateCoordinates(lat, lng)
    this.updateMap()
    this.placeMarker(lat, lng)
  }

  updateCoordinates(lat, lng) {
    console.log("Updating coordinates to:", lat, lng)

    if (!this.hasLatitudeTarget || !this.hasLongitudeTarget) {
      console.error("Missing latitude or longitude targets!")
      return
    }

    this.latitudeTarget.value = lat.toFixed(6)
    this.longitudeTarget.value = lng.toFixed(6)

    console.log("Updated input values:", this.latitudeTarget.value, this.longitudeTarget.value)

    // Trigger change event so Rails UJS knows the value changed
    this.latitudeTarget.dispatchEvent(new Event('change', { bubbles: true }))
    this.longitudeTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  // This is called when user manually types in lat/lng fields
  updateMap(event) {
    if (!this.hasMapTarget) {
      console.log("No map target found")
      return
    }

    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)

    if (isNaN(lat) || isNaN(lng)) {
      console.log("Invalid coordinates for map update")
      return
    }

    console.log("Updating map view to:", lat, lng)

    const mapController = this.getMapController()
    if (!mapController || !mapController.map) {
      console.log("Map controller not ready yet")
      return
    }

    mapController.map.setView([lat, lng], 18)
  }

  placeMarker(lat, lng) {
    const mapController = this.getMapController()

    if (mapController && typeof mapController.setMarker === "function") {
      mapController.setMarker(lat, lng)
    }
  }

  getMapController() {
    if (!this.hasMapTarget) return null

    return this.application.getControllerForElementAndIdentifier(
      this.mapTarget,
      "map"
    )
  }
}