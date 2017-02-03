class CallbacksController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:success, :fail]

  def success
    customer_id = params[:data][:customer_id]
    login_id = params[:data][:login_id]
    SpectreClient.new.fetch_everything(customer_id)
  end

  def fail
    login_id = params[:data][:login_id]
    error_message = params[:data][:error_message]
    flash[:danger] = "Could not update login /##{login_id}! Reason: #{error_message}"
    flash.keep(:danger)
  end
end
