# frozen_string_literal: true

# == Schema Information
#
# Table name: ip_redes
#
#  id         :bigint           not null, primary key
#  rede       :inet
#  subnet     :integer          # deprecated - prefixo agora é armazenado na coluna rede
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
    return 0 if rede.blank?

    if familia == 'IPv6'
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
    ocupados = conexoes.pluck(:ip).map(&:to_s)
    para_array - ocupados
  end

  # Mantém compatibilidade com código legado que usa `to_a`
  alias to_a para_array

  # Mantém compatibilidade com código legado que usa `prefix`
  alias prefix prefixo

  # Mantém compatibilidade com código legado que usa `ips_quantidade`
  alias ips_quantidade quantidade_ips

  # Mantém compatibilidade com código legado que usa `family`
  alias family familia

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
