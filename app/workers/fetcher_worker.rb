class FetcherWorker
  include Sidekiq::Worker

  def perform(customer_id)
    SpectreClient.new.fetch_everything(customer_id)
  end
end
