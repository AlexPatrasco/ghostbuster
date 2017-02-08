require 'rails_helper'

describe User::LoginsController do
  let(:base_url) {Settings.API.Spectre.base_url}
  before(:each) do 
    customer_id = JSON.parse(SpectreClient.new.request('get', base_url + 'customers').body)['data'][0]['id']
    @customer = FactoryGirl.create(:user, customer_id: customer_id)
    sign_in @customer, scope: :user
  end

  describe '#new' do
    let(:response) {SpectreClient.new.fetch_token(@customer.customer_id, 'customer', 'create')}
    let(:redirect_url) {JSON.parse(response.body)['data']['connect_url']}

    it 'redirects to saltedge connect for login creation' do
      expect_any_instance_of(SpectreClient).to receive(:fetch_token).with(@customer.customer_id, 'customer', 'create').and_return(response)

      get 'new'
      
      expect(subject).to redirect_to(redirect_url)
    end
  end
end