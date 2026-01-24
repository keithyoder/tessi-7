import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.initializeMap();
  }

  initializeMap() {
    // Wait for Google Maps API to load
    if (typeof google === 'undefined' || !google.maps) {
      setTimeout(() => this.initializeMap(), 100);
      return;
    }

    // Read lat/lng from form inputs
    const latInput = document.getElementById("conexao_latitude");
    const lngInput = document.getElementById("conexao_longitude");
    
    const lat = parseFloat(latInput?.value) || -15.7942; // Default to center of Brazil if empty
    const lng = parseFloat(lngInput?.value) || -47.8822;

    const latlng = new google.maps.LatLng(lat, lng);

    const map = new google.maps.Map(this.element, {
      zoom: 18,
      center: latlng
    });

    const marker = new google.maps.Marker({
      map: map,
      position: latlng,
      draggable: true
    });

    marker.addListener("dragend", (evt) => {
      if (latInput) latInput.value = evt.latLng.lat();
      if (lngInput) lngInput.value = evt.latLng.lng();
    });
  }
}