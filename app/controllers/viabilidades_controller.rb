# frozen_string_literal: true

class ViabilidadesController < ApplicationController
  load_and_authorize_resource :conexao

  def show; end

  def create; end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def viabilidades_params
    params.permit(:lat, :lon, :url)
  end
end
