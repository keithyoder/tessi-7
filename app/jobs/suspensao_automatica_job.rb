# frozen_string_literal: true

class SuspensaoAutomaticaJob < ApplicationJob
  queue_as :default

  def perform
    Contrato.eager_load(:conexoes).ativos.each(&:atualizar_conexoes)
  end
end
