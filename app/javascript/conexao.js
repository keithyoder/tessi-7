// Place all the behaviors and hooks related to the matching controller here.
// This logic is available in application.js

function success(pos) {
  const crd = pos.coords;
  $('#conexao_latitude').val(crd.latitude);
  $('#conexao_longitude').val(crd.longitude);

  console.log('Your current position is:');
  console.log(`Latitude : ${crd.latitude}`);
  console.log(`Longitude: ${crd.longitude}`);
  console.log(`More or less ${crd.accuracy} meters.`);
}

function error(err) {
  console.warn(`ERROR(${err.code}): ${err.message}`);
}

window.getConexaoLocation = function () {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      success,
      error,
      {
        enableHighAccuracy: true,
        timeout: 60000,
        maximumAge: 0
      }
    );
  }
};

window.carregarIPs = function () {
  const ponto = $('#conexao_ponto_id').val();

  $.ajax({
    url: `/pontos/${ponto}.json?ipv4`,
    method: 'GET',
    dataType: 'json',
    error: function (xhr, status, error) {
      console.error('AJAX Error: ' + status + error);
    },
    success: function (response) {
      const ips = response;
      const $select = $('#conexao_ip');

      $select.empty();
      ips.forEach(function (ip) {
        $select.append(`<option>${ip}</option>`);
      });
    }
  });
};

window.formatMAC = function () {
  let v = $('#conexao_mac').val().toUpperCase();
  const last = v.substring(v.lastIndexOf(':') + 1);

  if (last.length >= 2) {
    v += ':';
  }

  if (v.length > 17) {
    v = v.substring(0, 17);
  }

  $('#conexao_mac').val(v);
};

window.criar_mapa = function () {
  const latlng = new google.maps.LatLng(
    $('#conexao_latitude').val(),
    $('#conexao_longitude').val()
  );

  const map = new google.maps.Map(
    document.getElementById('map_canvas'),
    {
      zoom: 18,
      center: latlng
    }
  );

  const myMarker = new google.maps.Marker({
    map: map,
    position: latlng,
    draggable: true
  });

  google.maps.event.addListener(myMarker, 'dragend', function (evt) {
    $('#conexao_latitude').val(evt.latLng.lat());
    $('#conexao_longitude').val(evt.latLng.lng());
  });
};
