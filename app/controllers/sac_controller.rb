# frozen_string_literal: true

class SacController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check
  before_action :set_conexao

  def inadimplencia
    @vencimento = @conexao&.contrato&.faturas&.vencidas&.first&.vencimento
    @suspensao = @vencimento + 15.days if @vencimento
  end

  def suspensao
    @vencimento = @conexao&.contrato&.faturas&.vencidas&.first&.vencimento
  end

  private

  def set_conexao
    puts request
    ip = request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
    @conexao = Conexao.find_by(ip: ip)
    # @conexao = Conexao.find_by(ip: '10.36.1.107')
  end
end
