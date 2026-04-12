# frozen_string_literal: true

class SettingsController < ApplicationController
  # load_and_authorize_resource
  skip_authorization_check

  def create
    setting_params.each_key do |key|
      Setting.send("#{key}=", setting_params[key].strip) unless setting_params[key].nil?
    end
    redirect_to settings_path, notice: t('.notice')
  end

  private

  def setting_params
    params.require(:setting).permit(:razao_social, :cnpj, :juros, :multa, :ie, :telefone, :site)
  end
end
