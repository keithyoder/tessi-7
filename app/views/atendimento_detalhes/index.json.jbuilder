# frozen_string_literal: true

json.array! @atendimento_detalhes, partial: 'atendimento_detalhes/atendimento_detalhe', as: :atendimento_detalhe
