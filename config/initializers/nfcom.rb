# frozen_string_literal: true

require 'nfcom'

Nfcom.configure do |config|
  credentials = Rails.application.credentials.nfcom
  
  config.cnpj = credentials[:cnpj]
  config.inscricao_estadual = credentials[:inscricao_estadual]
  config.razao_social = credentials[:razao_social]
  config.regime_tributario = credentials[:regime_tributario]
  config.estado = credentials[:uf]
  config.ambiente = credentials[:ambiente]&.to_sym || :homologacao
  
  # Certificate configuration
  config.certificado_path = credentials[:certificado_path]
  config.certificado_senha = credentials[:certificado_senha]

  # Opcional
  config.serie_padrao = 1
  config.timeout = 60
  config.max_tentativas = 3
  config.log_level = :info
end