# frozen_string_literal: true

class MonitorarServidoresJob < ApplicationJob
  # include Sidekiq::Worker

  def perform
    Servidor.ativo.includes(:device).find_each do |servidor|
      device = servidor.device
      unless device
        Rails.logger.warn("[Monitorar Servidores] #{servidor.nome} sem device Mikrotik associado")
        next
      end

      resultado = device.atualizar!
      servidor.update_columns(up: resultado.present?)
    rescue StandardError => e
      Rails.logger.error("[Monitorar Servidores] #{servidor.nome}: #{e.message}")
      servidor.update_columns(up: false)
    end
  end
end

# Sidekiq::Cron::Job.create(name: 'Monitorar Concentradores - cada 5 min', cron: '*/5 * * * *', class: 'MonitorarServidoresJob')
