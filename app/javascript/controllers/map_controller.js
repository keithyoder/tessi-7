// app/javascript/controllers/map_controller.js
import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Fix Leaflet's default icon paths for esbuild
import iconUrl from 'leaflet/dist/images/marker-icon.png'
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png'
import shadowUrl from 'leaflet/dist/images/marker-shadow.png'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconUrl,
  iconRetinaUrl,
  shadowUrl
})

export default class extends Controller {
  static values = {
    latitude: Number,
    longitude: Number,
    zoom: { type: Number, default: 18 },
    markers: { type: Array, default: [] },
    googleApiKey: String
  }

  connect() {
    console.log("Map controller connected")
    console.log("Lat:", this.latitudeValue, "Lng:", this.longitudeValue)
    
    // Wait for next frame to ensure DOM is ready
    requestAnimationFrame(() => {
      this.initializeMap()
    })
  }

  initializeMap() {
    // Check if element has dimensions
    const rect = this.element.getBoundingClientRect()
    console.log("Element dimensions:", rect.width, rect.height)
    
    if (rect.height === 0) {
      console.error("Map container has no height!")
      return
    }

    // Google Maps tile layers
    const satellite = L.tileLayer(`https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}`, {
      attribution: '© Google',
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3']
    })

    const hybrid = L.tileLayer(`https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}`, {
      attribution: '© Google',
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3']
    })

    const streets = L.tileLayer(`https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}`, {
      attribution: '© Google',
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3']
    })

    // Initialize map
    try {
      this.map = L.map(this.element, {
        center: [this.latitudeValue, this.longitudeValue],
        zoom: this.zoomValue,
        layers: [hybrid]
      })

      console.log("Map initialized successfully")

      // Add layer control
      L.control.layers({
        "Híbrido": hybrid,
        "Satélite": satellite,
        "Ruas": streets
      }, null, {
        position: 'topright'
      }).addTo(this.map)

      // Add markers
      this.addMarkers()
      
      // Force map to recalculate size
      setTimeout(() => {
        this.map.invalidateSize()
      }, 100)
      
    } catch (error) {
      console.error("Error initializing map:", error)
    }
  }

  addMarkers() {
    if (!this.hasMarkersValue || this.markersValue.length === 0) {
      console.log("No markers to add")
      return
    }

    console.log("Adding", this.markersValue.length, "markers")
    console.log("Markers data:", this.markersValue)
    const bounds = []

    this.markersValue.forEach(marker => {
      const lat = parseFloat(marker.lat)
      const lng = parseFloat(marker.lng)
      
      if (isNaN(lat) || isNaN(lng)) {
        console.error("Invalid marker coordinates:", marker)
        return
      }

      console.log("Marker:", marker.title, "Color:", marker.color, "Icon:", marker.icon)

      let m

      // Use colored circle markers if color is provided
      if (marker.color) {
        m = L.circleMarker([lat, lng], {
          radius: 10,
          fillColor: marker.color,
          color: '#fff',
          weight: 3,
          opacity: 1,
          fillOpacity: 0.9,
          title: marker.title
        }).addTo(this.map)
      } else {
        // Fallback to regular marker
        m = L.marker([lat, lng], {
          title: marker.title
        }).addTo(this.map)

        // Custom icon for different marker types (old behavior)
        if (marker.icon) {
          const icon = L.divIcon({
            className: 'custom-marker',
            html: `<div class="marker-${marker.icon}">${marker.label || ''}</div>`,
            iconSize: [30, 30]
          })
          m.setIcon(icon)
        }
      }

      if (marker.popup) {
        m.bindPopup(marker.popup)
      }

      bounds.push([lat, lng])
    })

    // Fit bounds if multiple markers
    if (bounds.length > 1) {
      this.map.fitBounds(bounds, { padding: [50, 50] })
    }
  }

  disconnect() {
    console.log("Map controller disconnecting")
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}