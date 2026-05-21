# frozen_string_literal: true

json.array! @pessoas do |pessoa|
  json.id    pessoa.id
  json.text  pessoa.nome
  json.cpf   pessoa.cpf
  json.endereco pessoa.logradouro&.endereco
end
