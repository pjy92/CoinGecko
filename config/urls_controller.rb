class UrlsController < ApplicationController
  def create
    url = Shortener::CreateUrl.new(
      original_url: params[:original_url]
    ).call

    render json: {
      short_url: "#{request.base_url}/#{url.short_code}",
      original_url: url.original_url
    }
  end

  def show
    url = Url.find_by!(short_code: params[:short_code])

    if url.expires_at.present? && url.expires_at < Time.current
      return render json: { error: "Link expired" }, status: :gone
    end

    redirect_to url.original_url, allow_other_host: true
  end
end
