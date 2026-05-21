# frozen_string_literal: true

json.array! @logradouros do |logradouro|
  json.id       logradouro.id
  json.text     logradouro.endereco
  json.cep      logradouro.cep
end
