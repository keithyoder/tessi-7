# frozen_string_literal: true

module IpRedesHelper
  def rede_inicio(ip_rede)
    fim = IPAddr.new ip_rede.rede.to_range.first.to_string
    fim.prefix = ip_rede.subnet || 32
    "#{fim}/#{fim.prefix}"
  end

  def rede_fim(ip_rede)
    fim = IPAddr.new ip_rede.rede.to_range.last.to_string
    fim.prefix = ip_rede.subnet || 32
    "#{fim}/#{fim.prefix}"
  end
end
