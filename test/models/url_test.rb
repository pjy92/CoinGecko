require "test_helper"

class UrlTest < ActiveSupport::TestCase
  test "URL requires original_url" do
    url = Url.new(short_code: "abc123", title: "Test")
    assert_not url.valid?
    assert_includes url.errors[:original_url], "can't be blank"
  end

  test "URL requires short_code" do
    url = Url.new(original_url: "https://example.com", title: "Test")
    assert_not url.valid?
    assert_includes url.errors[:short_code], "can't be blank"
  end

  test "short_code must be unique" do
    Url.create!(original_url: "https://example.com", short_code: "abc123")
    url = Url.new(original_url: "https://different.com", short_code: "abc123")
    assert_not url.valid?
    assert_includes url.errors[:short_code], "has already been taken"
  end

  test "short_code length must not exceed 15 characters" do
    url = Url.new(
      original_url: "https://example.com",
      short_code: "a" * 16,
      title: "Test"
    )
    assert_not url.valid?
    assert_includes url.errors[:short_code], "is too long"
  end

  test "URL has many url_visits" do
    url = Url.create!(original_url: "https://example.com", short_code: "abc123")
    url.url_visits.create!(ip_address: "192.168.1.1", country: "US")
    url.url_visits.create!(ip_address: "192.168.1.2", country: "UK")
    assert_equal 2, url.url_visits.count
  end

  test "URL dependent destroy removes associated visits" do
    url = Url.create!(original_url: "https://example.com", short_code: "abc123")
    url.url_visits.create!(ip_address: "192.168.1.1")
    assert_equal 1, UrlVisit.count
    url.destroy
    assert_equal 0, UrlVisit.count
  end

  test "URL click_count defaults to 0" do
    url = Url.create!(original_url: "https://example.com", short_code: "abc123")
    assert_equal 0, url.clicks_count
  end
end
