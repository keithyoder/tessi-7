# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :debug_csrf
  check_authorization unless: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html { redirect_to main_app.root_url, notice: exception.message }
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end

  private

  def debug_csrf
    return unless devise_controller?

    Rails.logger.info '=' * 80
    Rails.logger.info "CSRF DEBUG - Controller: #{controller_name}##{action_name}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "Session CSRF Token: #{session[:_csrf_token]}"
    Rails.logger.info "Form Authenticity Token: #{form_authenticity_token}"
    Rails.logger.info "Params Token: #{params[:authenticity_token]}"
    Rails.logger.info "Request Format: #{request.format}"
    Rails.logger.info '=' * 80
  end
end
