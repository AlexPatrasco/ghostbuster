require 'json'
require 'rest-client'
require 'base64'
require 'openssl'

class SpectreClient
  attr_reader :client_id, :secret, :pem_path 
  TIME_OUT = 60 
  def initialize(client_id, secret, pem_path)
    @client_id = client_id
    @secret = secret
    @pem_path = File.open pem_path
  end

  def request(method, url, **params)
    hash = {
      method: method,
      url: url,
      params: as_json(params),
      expires_at: (Time.now + TIME_OUT).to_i
    }

    RestClient::Request.execute(
      method: hash[:method],
      url: hash[:url],
      payload: hash[:params],
      headers: {
        'Accept' => "application/json",
        'Content-type' => "application/json",
        'Expires-at' => hash[:expires_at],
        'Signature' => signature(hash),
        'Client-id' => 'MvkmSXVO4uFykCI4Gc743w',
        'Service-secret' => '7CxCyraXL-cvmhlE7Loc-48EVAVQ6VKUNRtftZh8d44'
      }
    )
  end

  private

  def signature(hash)
    Base64.encode64(rsa_key.sign(digest, "#{hash[:expires_at]}|#{hash[:method]}|#{hash[:url]}|#{hash[:params]}")).delete("\n")
  end

  def rsa_key
    @rsa_key ||= OpenSSL::PKey::RSA.new @pem_path
  end

  def digest
    OpenSSL::Digest::SHA1.new
  end

  def as_json(data)
    data.empty? ? '' : data.to_json
  end
end