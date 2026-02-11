# frozen_string_literal: true

module Ubiquiti
  class ModelNormalizer
    # Patterns mapped to the canonical enum key
    # Order matters — first match wins
    PATTERNS = [
      { match: /loco\s*m5/i,        equipamento: 'NanoStation loco M5' },
      { match: /rocket\s*m5/i,      equipamento: 'Rocket M5' },
      { match: /liteap ac/i,        equipamento: 'Litebeam AC-16-120' },
      { match: /powerbeam\s*m5/i,   equipamento: 'Powerbeam M5' },
      { match: /nanostation\s*m5/i, equipamento: 'NanoStation M5' },
      { match: /nanobeam\s*m5/i,    equipamento: 'NanoBeam M5' },
      { match: /liteap gps/i, equipamento: 'LiteAP GPS' }
    ].freeze

    def self.resolve(snmp_modelo)
      return nil if snmp_modelo.blank?

      match = PATTERNS.find { |p| snmp_modelo.match?(p[:match]) }

      if match
        match[:equipamento]
      else
        Rails.logger.warn("Modelo SNMP desconhecido: #{snmp_modelo}")
        nil
      end
    end
  end
end
