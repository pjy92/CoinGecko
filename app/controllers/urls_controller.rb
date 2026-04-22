class UrlsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ArgumentError, with: :bad_request

  skip_before_action :verify_authenticity_token, if: -> {
    request.content_type&.include?("application/json") || request.accept&.include?("application/json")
  }

  def create
    result = Shortener::CreateUrl.call(url: params[:url])

    respond_to do |format|
      format.html do
        @short_url = request.base_url + "/" + result[:short_url]
        @original_url = params[:url]
        @title = result[:title]
        render "home/index"
      end

      format.json do
        render json: {
          short_url: request.base_url + "/" + result[:short_url],
          original_url: params[:url],
          title: result[:title]
        }
      end
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.html do
        flash[:error] = e.message
        render "home/index"
      end
      format.json do
        render json: { error: e.message }, status: :bad_request
      end
    end
  end

  def show
    url = Url.find_by!(short_code: params[:short_code])

    url.increment!(:clicks_count)

    ip = request.remote_ip == "::1" ? "8.8.8.8" : request.remote_ip
    result = Geocoder.search(ip).first
    country = result&.country

    url.url_visits.create!(
      ip_address: request.remote_ip,
      visited_at: Time.current,
      country: country
    )

    redirect_to url.original_url, allow_other_host: true
  end

  private

  def not_found
    render json: { error: "Short URL not found" }, status: :not_found
  end

  def bad_request(e)
    render json: { error: e.message }, status: :bad_request
  end
end
