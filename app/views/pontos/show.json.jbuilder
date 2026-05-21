# frozen_string_literal: true

json.tecnologia @ponto.tecnologia

json.ipv4 @ponto.ipv4_disponiveis.map(&:to_s)
json.ipv6 @ponto.ipv6_disponiveis.map(&:to_s)

json.caixas @ponto.caixas.order(:nome) do |caixa|
  json.id   caixa.id
  json.nome caixa.nome
end
