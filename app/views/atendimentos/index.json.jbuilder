# frozen_string_literal: true

json.array! @atendimentos, partial: 'atendimentos/atendimento', as: :atendimento
