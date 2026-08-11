# frozen_string_literal: true

# == Schema Information
#
# Table name: ip_redes
#
#  id         :bigint           not null, primary key
#  rede       :inet
#  subnet     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ponto_id   :bigint
#
# Indexes
#
#  index_ip_redes_on_ponto_id  (ponto_id)
#
class IpRede < ApplicationRecord
  include Ransackable

  belongs_to :ponto

  scope :ipv4, -> { where('family(rede) = 4') }
  scope :ipv6, -> { where('family(rede) = 6') }

  scope :with_conexoes_count, lambda {
    joins(<<~SQL.squish)
      LEFT JOIN conexoes ON conexoes.ip << ip_redes.rede
    SQL
      .group('ip_redes.id')
      .select('ip_redes.*, COUNT(conexoes.id)::integer as conexoes_count')
  }

  validate :nao_sobrepor_faixas

  # Atributos pesquisáveis via Ransack
  RANSACK_ATTRIBUTES = %w[rede_string].freeze
  RANSACK_ASSOCIATIONS = %w[ponto].freeze

  ransacker :rede_string do
    Arel.sql('rede::text')
  end

  # Retorna a notação CIDR diretamente da coluna rede
  # O tipo inet do PostgreSQL armazena o CIDR completo (ex: "192.168.1.0/24")
  def cidr
    return if rede.blank?

    "#{rede}/#{rede.prefix}"
  end

  # Extrai o comprimento do prefixo da notação CIDR
  # Ex: "192.168.1.0/24" retorna 24
  def prefixo
    return if rede.blank?

    rede.prefix
  end

  # Calcula o número total de endereços IP utilizáveis na faixa
  # Para IPv4: exclui endereços de rede e broadcast
  # Para IPv6: inclui todos os endereços
  def quantidade_ips
    return @quantidade_ips if defined?(@quantidade_ips)

    @quantidade_ips = if rede.blank?
                        0
                      elsif familia == 'IPv6'
                        2**(128 - prefixo)
                      else
                        (2**(32 - prefixo)) - 2
                      end
  end

  def familia
    # Determina a versão do IP pela coluna rede
    return 'IPv6' if rede.to_s.include?(':')

    'IPv4'
  end

  # Retorna um array com todos os endereços IP da faixa
  def para_array
    return [] if rede.blank?

    rede.to_range.to_a
  end

  def conexoes
    Conexao.rede_ip(cidr)
  end

  def ips_disponiveis
    ocupados = conexoes.pluck(:ip).to_a
    para_array - ocupados
  end

  BLOCO_IPV6_PADRAO = 56

  # Retorna os blocos /56 (ou outro tamanho) ainda não atribuídos a um cliente
  # dentro desta faixa IPv6. NUNCA enumera endereços individuais — isso
  # explodiria em pools IPv6 (um /48 tem 2^80 endereços).
  def blocos_ipv6_disponiveis(prefixo_bloco = BLOCO_IPV6_PADRAO) # rubocop:disable Metrics/AbcSize
    return [] if rede.blank? || familia != 'IPv6'
    raise ArgumentError, "bloco /#{prefixo_bloco} não cabe num pool /#{prefixo}" if prefixo_bloco < prefixo

    total_blocos = 2**(prefixo_bloco - prefixo)
    incremento   = 2**(128 - prefixo_bloco)
    inicio       = rede.to_range.first.to_i

    ocupados = Conexao.where.not(ipv6: nil).where('ipv6 << ?', cidr).pluck(:ipv6).map { |ip| IPAddr.new(ip.to_s) }

    (0...total_blocos).each_with_object([]) do |i, blocos|
      bloco = IPAddr.new(inicio + (i * incremento), Socket::AF_INET6).mask(prefixo_bloco)
      blocos << "#{bloco}/#{prefixo_bloco}" unless ocupados.any? { |ip| bloco.include?(ip) }
    end
  end

  # Mantém compatibilidade com código legado que usa `to_a`
  alias to_a para_array

  # Mantém compatibilidade com código legado que usa `prefix`
  alias prefix prefixo

  # Mantém compatibilidade com código legado que usa `ips_quantidade`
  alias ips_quantidade quantidade_ips

  # Mantém compatibilidade com código legado que usa `family`
  alias family familia

  def self.agrupar_conexoes(ip_redes, conexoes)
    ip_redes.each_with_object({}) do |rede, hash|
      next unless rede.rede

      cidr_range = rede.rede
      hash[rede.id] = conexoes.select do |conexao|
        conexao.ip && cidr_range.include?(conexao.ip)
      rescue IPAddr::InvalidAddressError
        false
      end
    rescue IPAddr::InvalidAddressError
      hash[rede.id] = []
    end
  end

  private

  # Valida que a faixa de IP não se sobrepõe a nenhuma faixa existente
  # Usa o operador && do PostgreSQL que retorna true se duas faixas inet se sobrepõem
  #
  # O operador && verifica se duas faixas têm algum IP em comum:
  # - '192.168.1.0/24' && '192.168.1.0/25' => true (segunda está contida na primeira)
  # - '192.168.1.0/24' && '192.168.2.0/24' => false (sem sobreposição)
  # - '192.168.1.0/24' && '192.168.1.128/25' => true (sobreposição parcial)
  def nao_sobrepor_faixas
    return if rede.blank?

    sobrepostas = IpRede
      .where.not(id: id || 0) # Exclui o próprio registro, trata novos registros com id || 0
      .where('rede && ?::inet', cidr)

    return unless sobrepostas.exists?

    # Fornece mensagem de erro útil com as faixas conflitantes
    faixas_sobrepostas = sobrepostas.map(&:cidr).join(', ')
    errors.add(:rede, "se sobrepõe à(s) faixa(s) de IP existente(s): #{faixas_sobrepostas}")
  end
end
