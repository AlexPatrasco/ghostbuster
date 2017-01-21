class User::LoginsController < ApplicationController
  before_action :authenticate_user!

  def index
    response = SpectreClient.new.request('get', Settings.API.Spectre.requests.logins.index, data:{customer_id: current_user.customer_id})
    @logins = JSON.parse(response.body)
  end

  def add_login
    response = SpectreClient.new.request('post', Settings.API.Spectre.requests.logins.index, data:{
        country_code: 'XF',
        provider_code: 'fakebank_simple_xf',
        customer_id: current_user.customer_id
      }
    )
    if response.code == 200
      redirect_to action: :index
    else
      flash[:notice] = 'An error occured while creating login!'
      redirect_to action: :index
    end
  end
end
