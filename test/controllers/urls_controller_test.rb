require "test_helper"

class UrlsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @url = Url.create!(
      original_url: "https://example.com",
      short_code: "abc123",
      title: "Example"
    )
  end

  # POST /shorten - Create Short URL Tests
  test "POST /shorten with valid URL creates short URL" do
    post "/shorten", params: { url: "https://google.com" }
    assert_response :success
    assert_match /Short URL/, response.body
  end

  test "POST /shorten returns JSON for JSON request" do
    post "/shorten", 
      params: { url: "https://google.com" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["short_url"]
    assert json["original_url"]
    assert json["title"]
  end

  test "POST /shorten with invalid URL returns error" do
    post "/shorten", 
      params: { url: "not-a-url" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
    assert_response :bad_request
    json = JSON.parse(response.body)
    assert json["error"]
  end

  test "POST /shorten with missing URL returns error" do
    post "/shorten", 
      params: { url: "" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
    assert_response :bad_request
  end

  # GET /:short_code - Redirect Tests
  test "GET /:short_code redirects to original URL" do
    get "/#{@url.short_code}"
    assert_redirected_to @url.original_url
  end

  test "GET /:short_code increments click count" do
    initial_clicks = @url.clicks_count
    get "/#{@url.short_code}"
    @url.reload
    assert_equal initial_clicks + 1, @url.clicks_count
  end

  test "GET /:short_code creates visit record" do
    assert_difference("UrlVisit.count") do
      get "/#{@url.short_code}"
    end
  end

  test "GET /invalid returns 404" do
    get "/invalid_code_xyz"
    assert_response :not_found
  end

  # Web form tests
  test "POST /shorten from web form works" do
    get "/"  # Get the form page to get authenticity token
    post "/shorten", params: { url: "https://example.com" }
    assert_response :success
  end

  # Edge cases
  test "POST /shorten with very long URL" do
    long_url = "https://example.com/" + "a" * 2000
    post "/shorten", 
      params: { url: long_url }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
    assert_response :success
  end

  test "POST /shorten with special characters in URL" do
    post "/shorten", 
      params: { url: "https://example.com/?q=hello%20world&id=123" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
    assert_response :success
  end
end
