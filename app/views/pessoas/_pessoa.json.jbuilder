# frozen_string_literal: true

json.extract! pessoa, :id, :nome, :tipo, :cpf, :cnpj, :rg, :ie, :nascimento, :logradouro_id, :numero, :complemento,
              :nomemae, :email, :telefone1, :telefone2, :created_at, :updated_at
json.url pessoa_url(pessoa, format: :json)
