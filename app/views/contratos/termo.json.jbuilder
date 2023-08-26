json.document do
  json.name "Termo #{@contrato.id}"
  json.footer "BOTTOM"
end
json.signers do
  json.child! do
    json.phone "+55#{@contrato.pessoa.telefone1.gsub(/[^0-9]/, '')}"
    json.delivery_method "DELIVERY_METHOD_WHATSAPP"
    json.action "SIGN"
    json.configs do
      json.cpf CPF.new(@contrato.pessoa.cpf).stripped
    end
  end
end