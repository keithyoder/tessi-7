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

// Make Leaflet globally available for other controllers
window.L = L

export default class extends Controller {
  static values = {
    latitude: Number,
    longitude: Number,
    zoom: { type: Number, default: 18 },
    markers: { type: Array, default: [] }
  }

  connect() {
    console.log("Map controller connected")
    console.log("Lat:", this.latitudeValue, "Lng:", this.longitudeValue)
    
    requestAnimationFrame(() => {
      this.initializeMap()
    })
  }

  initializeMap() {
    const rect = this.element.getBoundingClientRect()
    console.log("Element dimensions:", rect.width, rect.height)
    
    if (rect.height === 0) {
      console.error("Map container has no height!")
      return
    }

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

    try {
      this.map = L.map(this.element, {
        center: [this.latitudeValue, this.longitudeValue],
        zoom: this.zoomValue,
        layers: [hybrid]
      })

      console.log("Map initialized successfully")

      L.control.layers({
        "Híbrido": hybrid,
        "Satélite": satellite,
        "Ruas": streets
      }, null, {
        position: 'topright'
      }).addTo(this.map)

      this.addMarkers()
      
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

      console.log("Marker:", marker.title, "Color:", marker.color, "Draggable:", marker.draggable)

      let m

      // If draggable, use regular marker with custom circular icon
      // If not draggable, use circle marker
      if (marker.draggable) {
        // Create custom circular icon for draggable markers
        const customIcon = this.createCircleIcon(marker.color || '#007bff')
        
        m = L.marker([lat, lng], {
          icon: customIcon,
          draggable: true,
          title: marker.title
        }).addTo(this.map)

        // Handle drag events
        this.makeDraggable(m, marker)
      } else if (marker.color) {
        // Non-draggable circle marker
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

  createCircleIcon(color) {
    // Create a circular icon using HTML/CSS instead of SVG
    return L.divIcon({
      className: 'draggable-circle-marker',
      html: `<div class="circle-inner" style="background-color: ${color}"></div>`,
      iconSize: [24, 24],
      iconAnchor: [12, 12],
      popupAnchor: [0, -12]
    })
  }

  makeDraggable(marker, markerData) {
    let originalOpacity

    marker.on('dragstart', (e) => {
      console.log("Drag started")
      // Add dragging class for visual feedback
      const element = e.target.getElement()
      if (element) {
        element.classList.add('dragging')
      }
    })

    // marker.on('drag', (e) => {
    //   const latlng = e.target.getLatLng()
    //   console.log("Dragging to:", latlng.lat.toFixed(6), latlng.lng.toFixed(6))
    // })

    marker.on('dragend', (e) => {
      const latlng = e.target.getLatLng()
      console.log("Drag ended at:", latlng.lat.toFixed(6), latlng.lng.toFixed(6))
      
      // Remove dragging class
      const element = e.target.getElement()
      if (element) {
        element.classList.remove('dragging')
      }
      
      // Update popup if it exists
      if (markerData.popup) {
        const newPopup = `${markerData.title || 'Localização'}<br>Latitude: ${latlng.lat.toFixed(6)}<br>Longitude: ${latlng.lng.toFixed(6)}<br><em>Arraste para ajustar</em>`
        marker.setPopupContent(newPopup)
      }

      // Dispatch custom event with new coordinates
      const event = new CustomEvent('marker-moved', {
        detail: {
          lat: latlng.lat,
          lng: latlng.lng,
          markerId: markerData.id
        },
        bubbles: true
      })
      this.element.dispatchEvent(event)
    })
  }

  disconnect() {
    console.log("Map controller disconnecting")
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}