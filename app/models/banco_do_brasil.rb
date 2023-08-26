# frozen_string_literal: true

class BancoDoBrasil
  include HTTParty
  debug_output $stdout

  def oauth_token
    return @oauth_token unless oauth_expired?

    request_oauth_token
  end

  private

  def oauth_expired?
    @oauth_token.nil? || @oauth_expires_at < Time.now
  end

  def request_oauth_token
    response = self.class.post(
      'https://oauth.hm.bb.com.br/oauth/token/',
      body: {
        grant_type: 'client_credentials',
        scope: 'cobrancas.boletos-requisicao'
      },
      headers: oauth_headers
    )
    @oauth_expires_at = Time.now + response['expires_in'].to_i.seconds
    @oauth_token = response['access_token']
  end

  def oauth_headers
    {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': "Basic #{Rails.application.credentials.bb_auth}",
      'cache-control': 'no-cache'
    }
  end

  def format_date(date)
    return nil if date.nil?

    date.strftime('%d.%m.%Y')
  end
end
