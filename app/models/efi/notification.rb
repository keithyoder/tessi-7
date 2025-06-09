# frozen_string_literal: true

module Efi
  class Notification # rubocop:disable Style/Documentation
    def initialize(token)
      @token = token
    end

    def get
      Efi.cliente.getNotification(
        params: { token: @token }
      )
    end
  end
end
