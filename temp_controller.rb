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
