// Success callback for geolocation
const success = (pos) => {
  const crd = pos.coords;

  const latInput = document.getElementById('fibra_caixa_latitude');
  const lngInput = document.getElementById('fibra_caixa_longitude');

  if (latInput) latInput.value = crd.latitude;
  if (lngInput) lngInput.value = crd.longitude;

  console.log('Your current position is:');
  console.log(`Latitude : ${crd.latitude}`);
  console.log(`Longitude: ${crd.longitude}`);
  console.log(`More or less ${crd.accuracy} meters.`);
};

// Error callback for geolocation
const error = (err) => {
  console.warn(`ERROR(${err.code}): ${err.message}`);
};

// Expose getLocation to window
window.getLocation = () => {
  if (!navigator.geolocation) {
    console.warn('Geolocation is not supported by this browser.');
    return;
  }

  navigator.geolocation.getCurrentPosition(success, error, {
    enableHighAccuracy: true,
    timeout: 60000,
    maximumAge: 10
  });
};
