class AnalyticsController < ApplicationController
  def show
    url = Url.find_by!(short_code: params[:short_code])

    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i

    visits = url.url_visits
                .order(created_at: :desc)
                .offset((page - 1) * per_page)
                .limit(per_page)

    render json: {
      short_code: url.short_code,
      original_url: url.original_url,
      clicks: url.clicks_count,
      page: page,
      per_page: per_page,
      visits: visits.map do |v|
        {
          ip: v.ip_address,
          country: v.country,
          visited_at: v.visited_at
        }
      end
    }
  end
end
