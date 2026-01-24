# frozen_string_literal: true

class SuspensaoAutomaticaJob < ApplicationJob
  queue_as :default

  def perform
    contratos = Contrato.ativos.includes(:conexoes, :faturas, :excecoes)
    contratos.find_each(batch_size: 100, &:atualizar_conexoes)
  end
end
