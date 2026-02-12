# frozen_string_literal: true

module Ubiquiti
  class ModelNormalizer
    # Patterns mapped to the canonical enum key
    # Order matters — first match wins
    PATTERNS = [
      { match: /nanoloco|loco\s*m5/i,          modelo: 'NanoLoco M5' },
      { match: /rocket\s*m5/i,                 modelo: 'Rocket M5' },
      { match: /liteap ac/i,                   modelo: 'Litebeam AC-16-120' },
      { match: /litebeam.*5ac|lbe.*5ac/i,      modelo: 'Litebeam 5ac-gen2-br 23dbi' },
      { match: /litebeam.*ac.*16.*120/i,       modelo: 'Litebeam AC-16-120' },
      { match: /litebeam.*m5/i,                modelo: 'Litebeam M5 23dbi' },
      { match: /liteap gps/i,                  modelo: 'LiteAP GPS' },
      { match: /airgrid/i,                     modelo: 'Airgrid M5 23dbi' },
      { match: /nanobeam\s*m5/i,               modelo: 'Nanobeam M5 16dbi' },
      { match: /powerbeam\s*m5/i,              modelo: 'Powerbeam M5' },
      { match: /nanostation\s*m5/i,            modelo: 'NanoStation M5' }
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
