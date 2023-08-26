# frozen_string_literal: true

json.array! @pessoas, partial: 'pessoas/pessoa', as: :pessoa
