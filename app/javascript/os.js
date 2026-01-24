// Converts integer IP to dotted decimal string
const num2dot = (num) => {
  let d = num % 256;
  let i = 3;
  while (i > 0) {
    num = Math.floor(num / 256);
    d = (num % 256) + '.' + d;
    i--;
  }
  return d;
};

// Fetch and populate conexoes for a given pessoa
const carregarConexoes = async () => {
  const pessoaSelect = document.getElementById('os_pessoa_id');
  const conexaoSelect = document.getElementById('os_conexao_id');
  const pessoa = pessoaSelect.value;

  if (!pessoa) return;

  try {
    const response = await fetch(`/pessoas/${pessoa}.json?conexoes`, {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    });

    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

    const conexoes = await response.json();
    const conexaoSalvo = conexaoSelect.value;

    // Clear existing options
    conexaoSelect.innerHTML = '<option value="">--Escolher Conexão--</option>';

    // Add new options
    for (const conexao of conexoes) {
      const ip = num2dot(conexao.ip.addr);
      const option = document.createElement('option');
      option.value = conexao.id;
      option.textContent = `${ip} - ${conexao.usuario}`;
      conexaoSelect.appendChild(option);
    }

    // Restore previously selected value
    conexaoSelect.value = conexaoSalvo;

  } catch (error) {
    console.error('AJAX Error: ', error);
  }
};

// Set up event listener
document.addEventListener('DOMContentLoaded', () => {
  const pessoaSelect = document.getElementById('os_pessoa_id');
  if (pessoaSelect) {
    pessoaSelect.addEventListener('change', carregarConexoes);
    carregarConexoes(); // initial load
  }
});
