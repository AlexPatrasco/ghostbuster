class User::LoginsController < UserController

  def index
    @logins = current_user.logins
  end

  def new
    response = api.fetch_token(current_user.customer_id, 'customer', 'create')
    @connect_url = JSON.parse(response.body)['data']['connect_url']
    redirect_to @connect_url
  end

  def refresh
    response = api.fetch_token(params[:id], 'login', 'refresh')
    @connect_url = JSON.parse(response.body)['data']['connect_url']
    redirect_to @connect_url
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
    response = api.fetch_token(params[:id], 'login', 'reconnect')
    @connect_url = JSON.parse(response.body)['data']['connect_url']
    redirect_to @connect_url
  end
end
