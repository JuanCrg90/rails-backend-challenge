module Providers
  class AvailabilitiesController < ApplicationController
    # Expected params: from, to (ISO8601 timestamps)
    # GET /providers/:provider_id/availabilities?from=<iso8601>&to=<iso8601>
    def index
      provider = Provider.find(params[:provider_id])
      search = AvailabilitySearch.new(provider: provider)
      @availabilities = search.free_slots(
        from: params[:from],
        to: params[:to]
      )
      render json: @availabilities
    rescue ActiveRecord::RecordNotFound
      render json: { error: "provider not found" }, status: :not_found
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_content
    end
  end
end
