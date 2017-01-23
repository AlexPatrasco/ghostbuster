class User::LoginsController < UserController

  def index
    url = Settings.API.Spectre.base_url + 'logins/'
    response = api.request('get', url, customer_id: current_user.customer_id)
    @logins = JSON.parse(response.body)['data']
  end

  def new

  end

  def create
    url = Settings.API.Spectre.base_url + 'logins/'
    response = api.request('post', url, data: {
        country_code: 'XF',
        provider_code: 'fakebank_simple_xf',
        customer_id: current_user.customer_id,
        credentials: {
          login: params[:username],
          password: params[:password]
        }
      }
    )
    unless response.code == 200
      flash[:danger] = 'An error occured while creating login!'
    end
    redirect_to action: :index
  end

  def refresh
    url = Settings.API.Spectre.base_url + "logins/#{params[:id]}/refresh"
    response = api.request('put', url)
    if response.code == 200
      flash[:success] = 'Login refreshed successfully!'
    else
      flash[:warning] = 'Could not refresh login!'
    end
    redirect_to action: :index
  end

  def destroy
    url = Settings.API.Spectre.base_url + "logins/#{params[:id]}"
    response = api.request('delete', url)
    if response.code == 200
      flash[:success] = 'Login removed successfully!'
    else
      flash[:warning] = 'Could not remove login!'
    end
    redirect_to action: :index
  end

  def reconnect

  end

  def request_reconnection
    url = Settings.API.Spectre.base_url + "logins/#{params[:id]}/reconnect"
    response = api.request('put', url, data: {
      credentials: {
        login: params[:username],
        password: params[:password]
      }
    })
    if response.code == 200
      flash[:success] = 'Login reconnected successfully!'
    else
      flash[:warning] = 'Could not reconnect login!'
    end
    redirect_to action: :index
  end
end
