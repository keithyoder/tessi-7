# frozen_string_literal: true

# This class initializes the SdkRubyApisEfi client with the provided credentials.
# It is used to interact with the Efi API for various operations.
module Efi
  def self.cliente(**kwargs)
    perfil = PagamentoPerfil.find_by(banco: 364) if kwargs[:client_id].blank? && kwargs[:client_secret].blank?
    params = {
      client_id: kwargs[:client_id] || perfil.client_id,
      client_secret: kwargs[:client_secret] || perfil.client_secret,
      sandbox: ENV['RAILS_ENV'] != 'production'
    }

    params[:certificate] = kwargs[:certificate] if kwargs[:certificate].present?

    SdkRubyApisEfi.new(params)
  end
end
