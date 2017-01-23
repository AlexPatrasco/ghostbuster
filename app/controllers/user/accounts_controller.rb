class User::AccountsController < UserController

  def index
    url = Settings.API.Spectre.base_url + 'accounts/'
    @accounts = JSON.parse(api.request('get', url, login_id: params[:login_id]).body)['data']
  end
end
