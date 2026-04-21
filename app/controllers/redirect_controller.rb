class RedirectController < ApplicationController
  def show
    url = Url.find_by(short_code: params[:code])

    return render json: { error: "Not found" }, status: 404 unless url

    return render json: { error: "Expired" }, status: 410 if url.expired?

    url.increment!(:clicks_count)

    Visit.create!(
      url: url,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )

    redirect_to url.original_url, allow_other_host: true
  end
end
