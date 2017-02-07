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

  def fetch_entities(entity_type, parent_id, parent_type)
    entities = []
    if(Settings.Data.priority.index(entity_type) > Settings.Data.priority.index(parent_type))
      url = Settings.API.Spectre.base_url + entity_type.pluralize
      response = request('get', url, "#{parent_type}_id": parent_id)
      entities = JSON.parse(response.body)['data'] || []
    end
    entities
  end

  def fetch_and_persist(entity_type, parent_id, parent_type)
    entities = fetch_entities(entity_type, parent_id, parent_type)
    persist_entities(entities, entity_type) if entities.size > 0
  end

  def persist_entities(collection, entity_type)
    collection.each do |entity|
      entity["#{entity_type}_id"] = entity.delete('id')
      entity.slice!(*Settings.Data.keys.send(entity_type))
      tmp_entity = entity_type.classify.constantize.create_with(entity).find_or_initialize_by("#{entity_type}_id": entity["#{entity_type}_id"])
      tmp_entity.new_record? ? tmp_entity.save : tmp_entity.update_attributes(entity)
    end
  end

  def update_login(login_id, status)
    url = Settings.API.Spectre.base_url + "logins/#{login_id}"
    response = request('get', url)
    login = JSON.parse(response.body)['data']
    login['login_id'] = login.delete('id')
    login.slice!(*Settings.Data.keys.login)
    Login.find_by(login_id: login_id).update_attributes(login.merge('status': status))
  end

  def fetch_everything(customer_id)
    fetch_and_persist('login', customer_id, 'customer')
    Login.where(customer_id: customer_id).each do |login|
      fetch_and_persist('account', login.login_id, 'login')
      login.accounts.each do |account|
        fetch_and_persist('transaction', account.account_id, 'account')
      end
    end
  end

  def remove_login(login_id)
    url = Settings.API.Spectre.base_url + "logins/#{login_id}"
    response = request('delete', url)
    if response.code == 200
      login = Login.find_by(login_id: login_id)
      login.accounts.each do |account|
        account.transactions.destroy_all
        account.destroy
      end
      login.destroy
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
    data.nil? ? '' : data.to_json
  end
end