class User::TransactionsController < UserController

  def index
    url = Settings.API.Spectre.base_url + 'transactions/'
    @transactions = JSON.parse(api.request('get', url, account_id: params[:account_id]).body)['data']
  end
end
