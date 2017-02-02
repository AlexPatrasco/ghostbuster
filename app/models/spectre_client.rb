require 'json'
require 'rest-client'
require 'base64'
require 'openssl'

class SpectreClient

  def request(method, url, **params)
    hash = {
      method: method.upcase,
      url: url,
      params: as_json(params),
      expires_at: (Time.now + Settings.connection.time_out).to_i
    }
    begin
      RestClient::Request.execute(
        method: hash[:method],
        url: hash[:url],
        payload: hash[:params],
        headers: {
          'Accept' => "application/json",
          'Content-type' => "application/json",
          'Expires-at' => hash[:expires_at],
          'Signature' => signature(hash),
          'Client-id' => Settings.API.Spectre.client_id,
          'Service-secret' => Settings.API.Spectre.service_secret
        }
      )
    rescue => e
      e.response
    end
  end

  def fetch_token(entity_id, entity_type, token_type)
    token_url = Settings.API.Spectre.base_url + "tokens/#{token_type}"
    request('post', token_url, data: {"#{entity_type}_id": entity_id, javascript_callback_type: 'iframe'})
  end

  def fetch_logins(customer_id)
    url = Settings.API.Spectre.base_url + 'logins/'
    response = request('get', url, customer_id: customer_id)
    logins = JSON.parse(response.body)['data']
    logins.each do |login_params|
      login_params['login_id'] = login_params.delete('id')
      login_keys = %w(login_id customer_id provider_id provider_code provider_name status last_success_at)
      login_params.slice!(*login_keys)
      login = Login.where(login_id: login_params['login_id']).first_or_initialize(login_params)
      login.save
    end
  end

  private

  def signature(hash)
    Base64.encode64(rsa_key.sign(digest, "#{hash[:expires_at]}|#{hash[:method]}|#{hash[:url]}|#{hash[:params]}")).delete("\n")
  end

  def rsa_key
    private_pem = File.open(Settings.connection.private_pem_path)
    @rsa_key ||= OpenSSL::PKey::RSA.new private_pem
  end

  def digest
    OpenSSL::Digest::SHA1.new
  end

  def as_json(data)
    data.empty? ? '' : data.to_json
  end
end