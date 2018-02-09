class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    head :ok
    
    @json = params[:data][:object].as_json
    @json.deep_symbolize_keys!

    binding.pry
    # first check for the application
    if @json[:application] == "ca_14yEk8gp5dbBbYDnndXU9yTNM3Z3gyWS"
      KindfulClient.new.import_transaction(@json)
    end

    
  end

end