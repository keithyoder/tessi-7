# frozen_string_literal: true

class WebhookEventosController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_authorization_check
  before_action :validate_token

  FILTERED_HEADER_KEYS = %w[
    GATEWAY_INTERFACE
    HTTP_AUTHORIZATION
    ORIGINAL_FULLPATH
    ORIGINAL_SCRIPT_NAME
    PATH_INFO
    QUERY_STRING
    RAW_POST_DATA
    REQUEST_PATH
    REQUEST_URI
    SCRIPT_NAME
    SERVER_SOFTWARE
    warden
  ].freeze

  def create
    @evento = WebhookEvento.new(webhook: @webhook, body: payload, headers: filtered_headers)

    if @evento.save && WebhookEventoJob.perform_later(@evento.id)
      render json: { status: 202 }
    else
      render json: { status: 404, error: 'generic error message that makes people mad' }, status: :bad_request
    end
  end

  private

  def validate_token
    return if (@webhook = Webhook.find_by(token: params[:token]))

    response = { errors: { token: ['Unknown token'] } }
    render json: response, status: :unprocessable_content
  end

  def payload
    params.except(:token, :webhook_evento, :action, :controller)
  end

  def filtered_headers
    request.headers.env.reject do |key|
      key.to_s.include?('.') || FILTERED_HEADER_KEYS.include?(key)
    end
  end
end
