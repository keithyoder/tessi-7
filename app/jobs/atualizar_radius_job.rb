# frozen_string_literal: true

class AtualizarRadiusJob < ApplicationJob
  queue_as :default

  def perform
    Conexao.all.each(&:integrar)
  end
end

# AtualizarRadiusJob.perform_now()
