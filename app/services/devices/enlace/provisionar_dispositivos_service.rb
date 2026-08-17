# frozen_string_literal: true

# Verifica, via SNMP, os IPs configurados nas duas pontas de um enlace de
# rádio e cria os devices (Devices::Ubiquiti) correspondentes quando ainda
# não existirem.
#
# Uso:
#   resultado = Enlace::ProvisionarDispositivosService.new(enlace: enlace).call
#
#   resultado.criados    # => [<EnlaceExtremidade posicao: A>]
#   resultado.ignorados  # => { <extremidade B> => :sem_ip }
#
class Enlace::ProvisionarDispositivosService # rubocop:disable Style/ClassAndModuleChildren
  Resultado = Struct.new(:criados, :ignorados, keyword_init: true) do
    def algum_criado?
      criados.any?
    end
  end

  def initialize(enlace:)
    @enlace = enlace
  end

  def call
    raise ArgumentError, 'enlace precisa ser do tipo Radio' unless enlace.tecnologia_Radio?

    criados = []
    ignorados = {}

    enlace.extremidades.each do |extremidade|
      motivo = provisionar(extremidade)
      motivo == :criado ? criados << extremidade : ignorados[extremidade] = motivo
    end

    Resultado.new(criados: criados, ignorados: ignorados)
  end

  private

  attr_reader :enlace

  def provisionar(extremidade)
    return :ja_existia if extremidade.device.present?
    return :sem_ip if extremidade.ip.blank?

    device = Devices::Ubiquiti.new(deviceable: extremidade)
    device.atualizar_snmp! ? :criado : :inacessivel
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[Enlace ##{enlace.id}] falha ao criar device para extremidade ##{extremidade.id}: #{e.message}")
    :mac_duplicado
  end
end
