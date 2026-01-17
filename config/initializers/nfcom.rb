# frozen_string_literal: true

require 'nfcom'

Nfcom.configure do |config|
  # Ambiente
  config.ambiente = :producao
  config.estado = 'PE'

  # Certificado digital
  config.certificado_path = ENV['NFCOM_CERTIFICADO_PATH']
  config.certificado_senha = ENV['NFCOM_CERTIFICADO_SENHA']

  # Dados do emitente
  config.cnpj = ENV['NFCOM_CNPJ']
  config.razao_social = ENV['NFCOM_RAZAO_SOCIAL']
  config.inscricao_estadual = ENV['NFCOM_INSCRICAO_ESTADUAL']
  config.regime_tributario = :simples_nacional

  # Opcional
  config.serie_padrao = 1
  config.timeout = 60
  config.max_tentativas = 3
  config.log_level = :info
end
