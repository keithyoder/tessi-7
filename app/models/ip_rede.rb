# frozen_string_literal: true

class IpRede < ApplicationRecord
  belongs_to :ponto
  scope :ipv4, -> { where('family(rede) = 4') }
  scope :ipv6, -> { where('family(rede) = 6') }
  ransacker :rede_string do
    Arel.sql('rede::text')
  end

  def cidr
    "#{rede}/#{rede.prefix}" unless rede.nil?
  end

  def ips_quantidade
    if rede.ipv6?
      2**(56 - rede.prefix)
    else
      rede.to_range.count - 4
    end
  end

  def to_a
    if rede.ipv6?
      ipv6_array
    else
      rede.to_range.map(&:to_s)[3...-1]
    end
  end

  def conexoes
    Conexao.rede_ip(cidr)
  end

  def ips_disponiveis
    ocupados = conexoes.map { |c| c.ip.to_s }
    to_a - ocupados
  end

  private

  def ipv6_array
    fim = rede.to_range.last.to_i
    ip = rede.to_range.first
    step = 2**(128 - subnet)
    resultado = []
    until ip.to_i > fim
      resultado << ip.to_s
      ip = IPAddr.new ip.to_i + step, Socket::AF_INET6
    end
    resultado
  end
end
