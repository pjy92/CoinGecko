require "test_helper"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @url = Url.create!(
      original_url: "https://example.com",
      short_code: "abc123",
      title: "Example",
      clicks_count: 3
    )

    # Create some visit records
    @url.url_visits.create!(
      ip_address: "192.168.1.1",
      country: "US",
      visited_at: 1.hour.ago
    )
    @url.url_visits.create!(
      ip_address: "10.0.0.1",
      country: "UK",
      visited_at: 2.hours.ago
    )
  end

  test "GET /analytics/:short_code returns analytics data" do
    get "/analytics/#{@url.short_code}"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "abc123", json["short_code"]
    assert_equal "https://example.com", json["original_url"]
    assert_equal 3, json["clicks"]
  end

  test "GET /analytics/:short_code includes visit details" do
    get "/analytics/#{@url.short_code}"
    json = JSON.parse(response.body)
    assert json["visits"].any?
    assert json["visits"][0]["ip"]
    assert json["visits"][0]["country"]
    assert json["visits"][0]["visited_at"]
  end

  test "GET /analytics/:short_code with pagination" do
    # Create more visits
    10.times do |i|
      @url.url_visits.create!(
        ip_address: "192.168.1.#{i}",
        country: "US",
        visited_at: i.hours.ago
      )
    end

    get "/analytics/#{@url.short_code}?page=1&per_page=5"
    json = JSON.parse(response.body)
    assert_equal 5, json["visits"].length
  end

  test "GET /analytics/:short_code with invalid code returns 404" do
    get "/analytics/invalid_code"
    assert_response :not_found
  end
end
