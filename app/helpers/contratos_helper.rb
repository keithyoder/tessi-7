# frozen_string_literal: true

module ContratosHelper
  def autentique_status(eventos)
    return 'visualizado' if eventos['opened'].present?
    return 'recebido' if eventos['delivered'].present?
    return 'enviado' if eventos['sent'].present?
  end
end
