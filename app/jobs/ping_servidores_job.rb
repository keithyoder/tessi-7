# frozen_string_literal: true

class PingServidoresJob < ApplicationJob
  # include Sidekiq::Worker

  def perform
    Servidor.ativo.each do |servidor|
      servidor.update!(up: servidor.ping?)
    end
  end
end

# Sidekiq::Cron::Job.create(name: 'Ping Concentradores - cada 5 min', cron: '*/5 * * * *', class: 'PingServidoresJob')
