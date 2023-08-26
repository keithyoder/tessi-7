# frozen_string_literal: true

class AtualizarConcentradoresEPontosJob < ApplicationJob
  queue_as :default

  def perform
    # Servidor.ativo.each do | servidor |
    #  begin
    #    info = servidor.system_info
    #    servidor.equipamento = info[:'board-name']
    #    servidor.versao = info[:version]
    #    servidor.save
    #  rescue => exception
    #  end
    # end
    Ponto.Ubnt.each(&:touch)
  end
end

# AtualizarConcentradoresEPontosJob.perform()
