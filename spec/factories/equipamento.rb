# frozen_string_literal: true

FactoryBot.define do
  factory :equipamento do
    modelo { 'RB912UAG-5HPnD' }
    tipo { :Radio }
    fabricante { 'MikroTik' }

    # ========================================================================
    # Traits por tipo de equipamento
    # ========================================================================

    # CPE - Customer Premises Equipment (equipamento do cliente)
    trait :cpe do
      tipo { :CPE }
      modelo { 'RB912UAG-5HPnD' }
    end

    # Router/Concentrador
    trait :routeador do
      tipo { :Roteador }
      modelo { 'RB4011iGS+' }
    end

    # ONU - Optical Network Unit (fibra)
    trait :onu do
      tipo { :ONU }
      modelo { 'GPON ONU AN5506-04' }
    end
  end
end
