require 'rails_helper'

describe SpectreClient do 

  before(:each) do
    @client = SpectreClient.new
  end

  describe '#digest' do
    it 'returns an instance of OpenSSL::Digest::SHA1' do 
      digest = @client.send(:digest)

      expect(digest).to be_an_instance_of(OpenSSL::Digest::SHA1)
    end
  end

  describe '#as_json' do
    context 'input data is empty' do
      it 'returns an empty string' do 
        data = nil

        empty_json = @client.send(:as_json, data)

        expect(empty_json).to eq('')
      end
    end

    context 'input data is not empty' do
      it 'returns a valid json' do 
        data = {a: 1, b: [1, 2, 'c']}

        valid_json = @client.send(:as_json, data)

        expect(valid_json).to eq(data.to_json)
      end
    end
  end

  describe '#rsa_key' do
    it 'loads a private key from pem certificate' do
      private_key = @client.send(:rsa_key)

      expect(private_key).to be_an_instance_of(OpenSSL::PKey::RSA)
    end
  end

  describe '#signature' do 
    it 'returns an encrypted signature' do 
      public_key = @client.send(:rsa_key).public_key
      digest = @client.send(:digest)
      hash = {
        expires_at:   1486371009,
        method:       'method',
        url:          'link',
        params:       ''
      }

      signature = @client.send(:signature, hash)

      expect(public_key.verify(digest, Base64.decode64(signature), hash.values.join('|'))).to eq(true)
    end
  end

  describe '#request' do
    it 'sends a request to a remote server' do
      hash = {
        method:     'GET',
        url:        'http://example.com',
        expires_at: Time.now.to_i + 60,
        params:     '{}'
      }

      expect(@client).to receive(:signature).with(hash).and_return('some sig')
      expect(RestClient::Request).to receive(:execute).with(
        method:  'GET',
        url:     'http://example.com',
        payload: '{}',
        headers: {
          'Accept'          => 'application/json',
          'Content-type'    => 'application/json',
          'Expires-at'      => Time.now.to_i + 60,
          'Signature'       => 'some sig',
          'Client-id'       => Settings.API.Spectre.client_id,
          'Service-secret'  => Settings.API.Spectre.service_secret
        }
      )

      @client.request('get', 'http://example.com')
    end
  end

  describe '#fetch_token' do
    context 'customer_id exists and token type is create' do
      it 'returns a valid login creation token and url' do 
        response = @client.fetch_token(203345, 'customer', 'create')

        expect(response.code).to eq(200)
        expect(response.body).to include('connect_url', 'token')
      end
    end

    context 'login_id exists and token type is refresh' do
      it 'returns a valid login refresh token and url' do
        response = @client.fetch_token(197166, 'login', 'refresh')

        expect(response.code).to eq(200)
        expect(response.body).to include('connect_url', 'token')
      end
    end

    context 'login_id exists and token type is reconnect' do 
      it 'returns a valid login reconnection token and url' do 
        response = @client.fetch_token(197166, 'login', 'reconnect')

        expect(response.code).to eq(200)
        expect(response.body).to include('connect_url', 'token')
      end
    end
  end

  describe '#update_login' do
    it 'fetches login data by id, finds corresponding record and updates it' do
      url = Settings.API.Spectre.base_url + 'logins'
      login = JSON.parse(@client.request('get', url).body)['data'][0]
      login_params = login.slice(*Settings.Data.keys.login)
      user = User.create(email: 'random@email.com', password: '123456', customer_id: login['customer_id'])
      tmp = user.logins.new(login_params.merge('login_id': login['id']))
      tmp.save

      @client.update_login(login['id'], 'new_status')

      @login = Login.find_by(login_id: login['id'])
      expect(@login.status).to eq('new_status')
      expect(@login.provider_id).to eq(login['provider_id'])
      expect(@login.provider_name).to eq(login['provider_name'])
      expect(@login.customer_id).to eq(login['customer_id'])
      expect(@login.login_id).to eq(login['id'])
      expect(@login.provider_code).to eq(login['provider_code'])
      expect(@login.last_success_at).to eq(login['last_success_at'])
    end
  end

  describe '#fetch_entities' do
    context 'entity and parent types do not satisfy hierarchy rules' do
      it 'returns an empty collection' do
        collection = @client.fetch_entities('login', 375222, 'account')

        expect(collection).to eq([])
      end
    end

    context 'entity and parent types satisfy hierarchy rules' do
      context 'invalid parent id is given' do
        it 'returns an empty collection' do 
          collection = @client.fetch_entities('transaction', 'abracadabra', 'account')

          expect(collection).to eq([])
        end
      end

      context 'valid parent id is given' do
        it 'returns a collection of entities' do 
          @client.request('post', Settings.API.Spectre.base_url + 'logins/', data:{
            customer_id: 203345,
            country_code: 'XF',
            provider_code: 'fakebank_simple_xf',
            credentials: {
              login: "username_#{Time.now.to_i}",
              password: 'secret'
            }
          })
          response = @client.request('get', Settings.API.Spectre.base_url + 'logins', customer_id: 203345)
          login_id = JSON.parse(response.body)['data'][0]['id']

          collection = @client.fetch_entities('account', login_id, 'login')

          expect(collection.size).to eq(3)
        end
      end
    end    
  end

  describe '#persist_entities' do 
    it 'persists fetched entities into database' do
      User.create(email: 'test@random.com', password: '123456', customer_id: 203345)
      logins = [
        JSON.parse(
          @client.request('get', Settings.API.Spectre.base_url + 'logins/197166').body
        )['data']
      ]

      expect(Login.find_by(login_id: 197166)).to eq(nil)

      @client.persist_entities(logins, 'login')

      expect(Login.last.login_id).to eq(logins[0]['login_id'])
      expect(Login.last.customer_id).to eq(logins[0]['customer_id'])
      expect(Login.last.provider_name).to eq(logins[0]['provider_name'])
      expect(Login.last.provider_code).to eq(logins[0]['provider_code'])
      expect(Login.last.provider_id).to eq(logins[0]['provider_id'])
    end
  end

  describe '#fetch_and_persist' do
    it 'calls fetch entities and then persists them' do
      User.create(email: 'test@random.com', password: '123456', customer_id: 203345)
      logins_fixture = JSON.parse(file_fixture('logins.json').read)

      expect(@client).to receive(:fetch_entities).with('login', 203345, 'customer').and_return(logins_fixture)
      expect(@client).to receive(:persist_entities).with(logins_fixture, 'login')

      @client.fetch_and_persist('login', 203345, 'customer')
    end
  end

  describe '#fetch_everything' do
    it 'fetches and persists all logins, accounts and transactions of a customer' do
      user = User.create(email: 'test@random.com', password: '123456', customer_id: 203345)

      expect(user.logins).to be_empty

      @client.fetch_everything(203345)

      expect(user.logins).not_to be_empty
      expect(user.logins.first.accounts).not_to be_empty
      expect(user.logins.first.accounts.first.transactions).not_to be_empty
    end
  end
end