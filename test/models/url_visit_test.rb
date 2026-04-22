require "test_helper"

class UrlVisitTest < ActiveSupport::TestCase
  setup do
    @url = Url.create!(original_url: "https://example.com", short_code: "abc123")
  end

  test "UrlVisit belongs to URL" do
    visit = @url.url_visits.create!(ip_address: "192.168.1.1", country: "US")
    assert_equal @url, visit.url
  end

  test "UrlVisit can be created with IP and country" do
    visit = @url.url_visits.create!(ip_address: "192.168.1.1", country: "US")
    assert visit.persisted?
    assert_equal "192.168.1.1", visit.ip_address
    assert_equal "US", visit.country
  end

  test "UrlVisit visited_at is recorded" do
    now = Time.current
    visit = @url.url_visits.create!(ip_address: "192.168.1.1", visited_at: now)
    assert_equal now.to_i, visit.visited_at.to_i
  end

  test "UrlVisit can be created without country (geolocation failure)" do
    visit = @url.url_visits.create!(ip_address: "192.168.1.1")
    assert visit.persisted?
    assert_nil visit.country
  end

  test "Multiple visits can be associated with single URL" do
    @url.url_visits.create!(ip_address: "192.168.1.1", country: "US")
    @url.url_visits.create!(ip_address: "192.168.1.2", country: "UK")
    @url.url_visits.create!(ip_address: "192.168.1.3", country: "CA")

    assert_equal 3, @url.url_visits.count
  end
end
