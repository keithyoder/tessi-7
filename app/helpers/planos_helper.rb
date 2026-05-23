# frozen_string_literal: true

module PlanosHelper
  def plano_velocidade(plano)
    "#{plano.download}M ▼ / #{plano.upload}M ▲"
  end

  def plano_burst(plano)
    plano.burst? ? 'Ativado' : 'Desativado'
  end
end
