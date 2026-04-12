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

    render html: '<div>Your State is not matched, consider it hacked.<div>'.html_safe and return if state != @state.to_s

    @code = params[:code]
    @realm_id = params[:realmId]

    result = exchange_code_for_token

    params.merge!(
      refresh_token: result['refresh_token'],
      expires_in: result['expires_in'],
      x_refresh_token_expires_in: result['x_refresh_token_expires_in'],
      access_token: result['access_token'],
      host_uri: @host_url.to_s
    )
  end

  def edit
    result = refresh_token

    params.merge!(
      updated_refresh_token: result['refresh_token'],
      updated_expires_in: result['expires_in'],
      updated_x_refresh_token_expires_in: result['x_refresh_token_expires_in'],
      updated_access_token: result['access_token'],
      host_uri: @host_url.to_s
    )
  end

  private

  # -----------------------------
  # Token exchange methods
  # -----------------------------
  def refresh_token
    load_config
    post_oauth_request(
      @exchange_url,
      grant_type: @refresh_token_scope.to_s,
      refresh_token: params[:id].to_s
    )
  end

  def exchange_code_for_token
    post_oauth_request(
      @exchange_url,
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

    raise "OAuth request failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  # -----------------------------
  # Config & URL helpers
  # -----------------------------
  def load_config
    config = YAML.load_file(Rails.root.join('config/oauth.yml'))
    load_settings_config(config['Settings'])
    load_oauth_config(config['OAuth2'])
    load_constants_config(config['Constant'])
  end

  def load_settings_config(settings)
    @host_url = settings['host_uri']
    @redirect_uri = settings['redirect_uri']
    @state = settings['state']
  end

  def load_oauth_config(oauth)
    @client_id = oauth['client_id']
    @client_secret = oauth['client_secret']
  end

  def load_constants_config(constants)
    @base_url = constants['baseURL']
    @exchange_url = constants['tokenURL']
    @scope = constants['scope']
    @refresh_token_scope = constants['resfresh_grant_type']
    @response_type = constants['response_type']
    @grant_type = constants['grant_type']
  end

  def construct_base_url
    load_config
    uri = URI(@base_url)
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
