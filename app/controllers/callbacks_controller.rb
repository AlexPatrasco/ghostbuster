class CallbacksController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:success, :fail]

  def success
    customer_id = params[:data][:customer_id]
    login_id = params[:data][:login_id]
    api.update_login(login_id, params[:data][:status])
    api.fetch_and_persist('account', login_id, 'login')
    Login.find_by(login_id: login_id).accounts.each do |account|
      api.fetch_and_persist('transaction', account.account_id, 'account')
    end
  end

  def fail
    login_id = params[:data][:login_id]
    customer_id = params[:data][:customer_id]
    error_message = params[:data][:error_message]
    api.update_login(login_id, error_message)
  end

  private

  def api
    api = SpectreClient.new
  end
end
