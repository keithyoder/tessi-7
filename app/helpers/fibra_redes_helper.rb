# frozen_string_literal: true

module FibraRedesHelper
  CORES_FIBRA = {
    1 => 'Verde',
    2 => 'Amarelo',
    3 => 'Branco',
    4 => 'Azul',
    5 => 'Vermelho',
    6 => 'Violeta',
    7 => 'Marrom',
    8 => 'Rosa',
    9 => 'Preto',
    10 => 'Cinza',
    11 => 'Laranja',
    12 => 'Aqua-marinha'
  }.freeze

  def opcoes_porta(max: 16)
    (1..max).map do |n|
      label = CORES_FIBRA[n] ? "#{n} - #{CORES_FIBRA[n]}" : n.to_s
      [label, n]
    end
  end
end
