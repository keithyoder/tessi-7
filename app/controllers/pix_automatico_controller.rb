# frozen_string_literal: true

class PixAutomaticoController < ApplicationController
  authorize_resource class: false
  before_action :set_pix_automatico

  def index
  end

  def show
  end

  def create
  end

  def destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_pix_automatico
    @contrato = Contrato.find(params[:contrato_id])
    @pix_automatico = Efi::PixAutomatico.new(@contrato)
  end
end
