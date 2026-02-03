# frozen_string_literal: true

module Faturamento
  class BaseController < ApplicationController
    before_action :authenticate_user!
    load_and_authorize_resource class: false

    layout 'application'

    private

    def authorize_faturamento!
      authorize! :read, :faturamento
    end
  end
end
