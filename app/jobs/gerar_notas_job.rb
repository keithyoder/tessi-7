# frozen_string_literal: true

class GerarNotasJob < ApplicationJob
  queue_as :default

  def perform
    range = Date.parse('2023-08-01')..Date.parse('2023-08-10')
    # range = 1.week.ago..1.day.ago
    Fatura.notas_a_emitir(range).each do |fatura|
      next_nf = Nf21.maximum(:numero) + 1
      fatura.create_nf21!(emissao: fatura.liquidacao, numero: next_nf)
    end
  end
end


Client_Id_3c95d4855186cedd58125f70e41eb4a7faeaed5c
Client_Secret_d36c05d6cb04fa10005b0c99b42dfbf0c612acfa

options = {
  client_id: 'Client_Id_3c95d4855186cedd58125f70e41eb4a7faeaed5c',
  client_secret: 'Client_Secret_d36c05d6cb04fa10005b0c99b42dfbf0c612acfa',
  pix_cert: 'homologacao.pem',
  sandbox: 'true'
}

{
  "calendario": {
    "dataDeVencimento": "2022-12-01",
    "validadeAposVencimento": 30
  },
  "devedor": {
    "logradouro": "Alameda Souza, Numero 80, Bairro Braz",
    "cidade": "Recife",
    "uf": "PE",
    "cep": "70011750",
    "cpf": "12345678909",
    "nome": "Francisco da Silva"
  },
  "loc": {
    "id": 3
  },
  "valor": {
    "original": "123.45",
    "multa": {
      "modalidade": 2,
      "valorPerc": "15.00"
    },
    "juros": {
      "modalidade": 2,
      "valorPerc": "2.00"
    },
    "desconto": {
      "modalidade": 1,
      "descontoDataFixa": [
        {
          "data": "2022-11-30",
          "valorPerc": "30.00"
        }
      ]
    }
  },
  "chave": "fc831fd6-1cd0-4d48-a804-1fdf51fbf2aa",
  "solicitacaoPagador": "Cobrança dos serviços prestados."
}