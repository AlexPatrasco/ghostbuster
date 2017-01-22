class User::LoginsController < ApplicationController
  before_action :authenticate_user!

  def index
    url = Settings.API.Spectre.base_url + 'logins/'
    response = api.request('get', url, data:{customer_id: current_user.customer_id})
    @logins = JSON.parse(response.body)
  end

  def new
    url = Settings.API.Spectre.base_url + 'logins/'
    token = api.fetch_token(current_user.customer_id)
    response = api.request('post', url, data:{
        country_code: 'XF',
        provider_code: 'fakebank_simple_xf',
        customer_id: current_user.customer_id,
        credentials: {
          login: 'username' + Time.now.to_s,
          password: 'secret'
        }
      }
    )
    unless response.code == 200
      flash[:notice] = 'An error occured while creating login!'
    end
    redirect_to action: :index
  end

  def show
    url = Settings.API.Spectre.base_url + 'accounts/'
    @accounts = JSON.parse(api.request('get', url, data: {login_id: params[:id]}).body)
  end

  private

  def api
    SpectreClient.new
  end
end
