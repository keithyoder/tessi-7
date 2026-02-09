# frozen_string_literal: true

FactoryBot.define do
  factory :ip_rede do
    # Associação obrigatória
    ponto

    # Sequência para gerar redes IPv4 não sobrepostas
    # Usa a faixa 10.0.0.0/8 (rede privada)
    sequence(:rede) { |n| "10.#{n / 256}.#{n % 256}.0/24" }

    # ========================================================================
    # Traits para diferentes tamanhos de rede IPv4
    # ========================================================================

    # Rede /30 - 2 hosts utilizáveis (ideal para links ponto-a-ponto)
    trait :rede_30 do
      sequence(:rede) { |n| "10.#{(n / 256) + 100}.#{n % 256}.0/30" }
    end

    # Rede /29 - 6 hosts utilizáveis
    trait :rede_29 do
      sequence(:rede) { |n| "10.#{(n / 256) + 110}.#{n % 256}.0/29" }
    end

    # Rede /28 - 14 hosts utilizáveis
    trait :rede_28 do
      sequence(:rede) { |n| "10.#{(n / 256) + 120}.#{n % 256}.0/28" }
    end

    # Rede /27 - 30 hosts utilizáveis
    trait :rede_27 do
      sequence(:rede) { |n| "10.#{(n / 256) + 130}.#{n % 256}.0/27" }
    end

    # Rede /26 - 62 hosts utilizáveis
    trait :rede_26 do
      sequence(:rede) { |n| "10.#{(n / 256) + 140}.#{n % 256}.0/26" }
    end

    # Rede /25 - 126 hosts utilizáveis
    trait :rede_25 do
      sequence(:rede) { |n| "10.#{(n / 256) + 150}.#{n % 256}.0/25" }
    end

    # Rede /24 - 254 hosts utilizáveis (padrão)
    trait :rede_24 do
      sequence(:rede) { |n| "10.#{n / 256}.#{n % 256}.0/24" }
    end

    # Rede /23 - 510 hosts utilizáveis
    trait :rede_23 do
      sequence(:rede) { |n| "10.#{(n / 128) * 2}.#{(n % 128) * 2}.0/23" }
    end

    # Rede /22 - 1022 hosts utilizáveis
    trait :rede_22 do
      sequence(:rede) { |n| "10.#{(n / 64) * 4}.#{(n % 64) * 4}.0/22" }
    end

    # Rede /21 - 2046 hosts utilizáveis
    trait :rede_21 do
      sequence(:rede) { |n| "10.#{(n / 32) * 8}.#{(n % 32) * 8}.0/21" }
    end

    # Rede /20 - 4094 hosts utilizáveis
    trait :rede_20 do
      sequence(:rede) { |n| "10.#{(n / 16) * 16}.#{(n % 16) * 16}.0/20" }
    end

    # ========================================================================
    # Traits para redes IPv6
    # ========================================================================

    # IPv6 padrão /64 (tamanho padrão de sub-rede)
    trait :ipv6 do
      sequence(:rede) { |n| format('2001:db8:%x::/64', n) }
    end

    # IPv6 /48 (prefixo típico para sites)
    trait :ipv6_48 do
      sequence(:rede) { |n| format('2001:db8:%x::/48', n) }
    end

    # IPv6 /56 (prefixo para ISPs menores)
    trait :ipv6_56 do
      sequence(:rede) { |n| format('2001:db8:%x::/56', n) }
    end

    # IPv6 /64 (sub-rede padrão)
    trait :ipv6_64 do
      sequence(:rede) { |n| format('2001:db8:%x::/64', n) }
    end

    # IPv6 /128 (host único)
    trait :ipv6_128 do
      sequence(:rede) { |n| format('2001:db8::%x/128', n) }
    end
  end
end
