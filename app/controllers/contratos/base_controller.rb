# frozen_string_literal: true

module Contratos
  class BaseController < ApplicationController
    before_action :set_contrato
    load_and_authorize_resource :contrato

    private

    def set_contrato
      @contrato = Contrato.find(params[:id])
    end
  end
end
