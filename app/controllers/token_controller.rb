# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'
require 'yaml'
require 'base64'
require 'json'

class TokenController < ApplicationController
  skip_authorization_check

  def index
    redirect_to construct_base_url.to_s
  end

  def new
    load_config
    state = params[:state].to_s

    if state != @state.to_s
      render html: '<div>Your State is not matched, consider it hacked.<div>'.html_safe and return
    end

    @code = params[:code]
    @realmID = params[:realmId]

    result = exchange_code_for_token

    params.merge!(
      refresh_token: result['refresh_token'],
      expires_in: result['expires_in'],
      x_refresh_token_expires_in: result['x_refresh_token_expires_in'],
      access_token: result['access_token'],
      host_uri: @hostURL.to_s
    )
  end

  def edit
    result = refresh_token

    params.merge!(
      updated_refresh_token: result['refresh_token'],
      updated_expires_in: result['expires_in'],
      updated_x_refresh_token_expires_in: result['x_refresh_token_expires_in'],
      updated_access_token: result['access_token'],
      host_uri: @hostURL.to_s
    )
  end

  private

  # -----------------------------
  # Token exchange methods
  # -----------------------------
  def refresh_token
    load_config
    post_oauth_request(
      @exchangeURL,
      grant_type: @refresh_token_scope.to_s,
      refresh_token: params[:id].to_s
    )
  end

  def exchange_code_for_token
    post_oauth_request(
      @exchangeURL,
      code: @code.to_s,
      grant_type: @grant_type.to_s,
      redirect_uri: @redirect_uri.to_s
    )
  end

  # -----------------------------
  # Generic POST to OAuth endpoint
  # -----------------------------
  def post_oauth_request(url_string, queryparams = {})
    uri = URI(url_string)
    header_value = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Accept' => 'application/json',
      'Authorization' => header_value
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER # <-- secure default

    req = Net::HTTP::Post.new(uri, headers)
    req.set_form_data(queryparams)

    response = http.request(req)

    unless response.is_a?(Net::HTTPSuccess)
      raise "OAuth request failed (#{response.code}): #{response.body}"
    end

    JSON.parse(response.body)
  end

  # -----------------------------
  # Config & URL helpers
  # -----------------------------
  def load_config
    config = YAML.load_file(Rails.root.join('config/oauth.yml'))
    @hostURL = config['Settings']['host_uri']
    @baseURL = config['Constant']['baseURL']
    @exchangeURL = config['Constant']['tokenURL']
    @client_id = config['OAuth2']['client_id']
    @client_secret = config['OAuth2']['client_secret']
    @scope = config['Constant']['scope']
    @refresh_token_scope = config['Constant']['resfresh_grant_type']
    @redirect_uri = config['Settings']['redirect_uri']
    @state = config['Settings']['state']
    @response_type = config['Constant']['response_type']
    @grant_type = config['Constant']['grant_type']
  end

  def construct_base_url
    load_config
    uri = URI(@baseURL)
    query_params = {
      client_id: @client_id,
      scope: @scope,
      redirect_uri: @redirect_uri,
      response_type: @response_type,
      state: @state
    }

    # Merge into any existing query string
    existing = URI.decode_www_form(uri.query || '') + query_params.to_a
    uri.query = URI.encode_www_form(existing)

    uri
  end
end
