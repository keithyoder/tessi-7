FactoryBot.define do
  factory :plano do
    nome        { 'Plano Default' }
    mensalidade { 100.0 }
    download    { 100 }  # in Mbps
    upload      { 50 }   # in Mbps
    burst       { false }
    ativo       { true }
    desconto    { 0.0 }
    gerencianet_id { nil }

    after(:create) do |plano|
      PlanoEnviarAtributo.where(plano: plano, atributo: 'Acct-Interim-Interval').first_or_create do |atr|
        atr.op = ':='
        atr.valor = '900'
      end

      PlanoVerificarAtributo.where(plano: plano, atributo: 'Simultaneous-Use').first_or_create do |atr|
        atr.op = ':='
        atr.valor = '1'
      end

      PlanoEnviarAtributo.where(plano: plano, atributo: 'Mikrotik-Rate-Limit').first_or_create do |atr|
        atr.op = '='
        atr.valor = plano.mikrotik_rate_limit
      end
    end
  end
end
