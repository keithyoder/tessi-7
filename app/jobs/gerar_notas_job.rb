# frozen_string_literal: true

class GerarNotasJob < ApplicationJob
  queue_as :default

  def perform
    range = Date.parse('2023-08-01')..Date.parse('2023-08-10')
    # range = 1.week.ago..1.day.ago
    Fatura.notas_a_emitir(range).each do |fatura|
      next_nf = Nf21.maximum(:numero) + 1
      fatura.create_nf21!(emissao: fatura.liquidacao, numero: next_nf)
    end
  end
end