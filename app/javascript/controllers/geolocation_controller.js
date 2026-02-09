// app/javascript/controllers/geolocation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "map"]

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
        
        this.updateCoordinates(lat, lng)
        
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

    // Get the map controller
    const mapController = this.application.getControllerForElementAndIdentifier(
      this.mapTarget,
      "map"
    )

    if (!mapController || !mapController.map) {
      console.log("Map controller not ready yet")
      return
    }

    // Update map center
    mapController.map.setView([lat, lng], 18)
  }
}