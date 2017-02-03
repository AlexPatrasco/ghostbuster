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
    request('post', token_url, data: {"#{entity_type}_id": entity_id, javascript_callback_type: 'iframe', return_to: 'http://morning-headland-56331.herokuapp.com/user/logins'})
  end

  def fetch_logins(customer_id)
    url = Settings.API.Spectre.base_url + 'logins/'
    response = request('get', url, customer_id: customer_id)
    login_keys = %w(login_id customer_id provider_id provider_code provider_name status last_success_at)
    logins = JSON.parse(response.body)['data']
    persist_entities(logins, 'login', login_keys)
  end

  def fetch_accounts(login_id)
    url = Settings.API.Spectre.base_url + 'accounts/'
    response = request('get', url, login_id: login_id)
    account_keys = %w(login_id account_id nature name currency_code balance)
    accounts = JSON.parse(response.body)['data']
    persist_entities(accounts, 'account', account_keys)
  end

  def fetch_transactions(account_id)
    url = Settings.API.Spectre.base_url + 'transactions/'
    response = request('get', url, account_id: account_id)
    transaction_keys = %w(transaction_id account_id status description made_on amount currency_code)
    transactions = JSON.parse(response.body)['data']
    persist_entities(transactions, 'transaction', transaction_keys)
  end

  def persist_entities(collection, entity_name, allowed_keys)
    collection.each do |entity|
      entity["#{entity_name}_id"] = entity.delete('id')
      entity.slice!(*allowed_keys)
      tmp_entity = entity_name.classify.constantize.create_with(entity).find_or_initialize_by("#{entity_name}_id": entity["#{entity_name}_id"])
      tmp_entity.new_record? ? tmp_entity.save : tmp_entity.update_attributes(entity)
    end
  end

  def update_login(login_id, status)
    url = Settings.API.Spectre.base_url + "logins/#{login_id}"
    response = request('get', url)
    login = JSON.parse(response.body)['data']
    login['login_id'] = login.delete('id')
    login_keys = %w(login_id customer_id provider_id provider_code provider_name status last_success_at)
    login.slice!(*login_keys)
    Login.find_by(login_id: login_id]).update_attributes(login.merge('status': status))
  end

  def fetch_everything(customer_id)
    fetch_logins(customer_id)
    Login.where(customer_id: customer_id).each do |login|
      fetch_accounts(login.login_id)
      login.accounts.each do |account|
        fetch_transactions(account.account_id)
      end
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