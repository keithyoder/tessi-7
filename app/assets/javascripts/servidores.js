// Converts an integer IP to dotted decimal string
const int2ip = (ipInt) => {
  return (
    (ipInt >>> 24) + '.' +
    ((ipInt >> 16) & 255) + '.' +
    ((ipInt >> 8) & 255) + '.' +
    (ipInt & 255)
  );
};

// Computes LatLngBounds from connected and disconnected points
const getBounds = (conectadas, desconectadas) => {
  const bounds = new google.maps.LatLngBounds();

  for (const conexao of conectadas) {
    const position = new google.maps.LatLng(
      parseFloat(conexao.latitude),
      parseFloat(conexao.longitude)
    );
    bounds.extend(position);
  }

  for (const conexao of desconectadas) {
    const position = new google.maps.LatLng(
      parseFloat(conexao.latitude),
      parseFloat(conexao.longitude)
    );
    bounds.extend(position);
  }

  return bounds;
};

// Creates a Google Maps InfoWindow for a connection
const infoWindow = (conexao) => {
  let endereco;
  if (conexao.logradouro_id == null) {
    endereco = `${conexao.logradouro_pessoa.nome}, ${conexao.pessoa.numero} - ${conexao.bairro.nome}`;
  } else {
    endereco = `${conexao.logradouro.nome}, ${conexao.numero} - ${conexao.bairro.nome}`;
  }

  return new google.maps.InfoWindow({
    content:
      `<h4><a href="/conexoes/${conexao.id}">${conexao.pessoa.nome}</a></h4>` +
      `<div id="bodyContent">${endereco}<br>` +
      `${conexao.ponto.nome} - ${int2ip(conexao.ip.addr)}</div>`
  });
};

// Creates a marker and attaches click listener
const criarMarker = (map, conexao, conectada) => {
  const position = {
    lat: parseFloat(conexao.latitude),
    lng: parseFloat(conexao.longitude)
  };

  const label = conectada ? '' : 'D';

  const marker = new google.maps.Marker({
    position: position,
    map: map,
    label: label
  });

  marker.addListener('click', () => {
    infoWindow(conexao).open(map, marker);
  });
};

// Initialize the map
window.initMap = () => {
  const mapElement = document.getElementById('map');
  const conectadas = mapElement.dataset.conectadas ? JSON.parse(mapElement.dataset.conectadas) : [];
  const desconectadas = mapElement.dataset.desconectadas ? JSON.parse(mapElement.dataset.desconectadas) : [];

  const map = new google.maps.Map(mapElement);
  map.fitBounds(getBounds(conectadas, desconectadas));

  for (const conexao of conectadas) {
    criarMarker(map, conexao, true);
  }

  for (const conexao of desconectadas) {
    criarMarker(map, conexao, false);
  }
};
