# frozen_string_literal: true

json.array! @cidades, partial: 'cidades/cidade', as: :cidade
