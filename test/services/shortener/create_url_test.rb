require "test_helper"

class Shortener::CreateUrlTest < ActiveSupport::TestCase
  test "CreateUrl creates URL with valid parameters" do
    result = Shortener::CreateUrl.call(url: "https://example.com")
    
    assert result[:short_url]
    assert_equal "https://example.com", result[:original_url]
    assert result[:title]
  end

  test "CreateUrl validates URL format" do
    error = assert_raises(ArgumentError) do
      Shortener::CreateUrl.call(url: "not-a-url")
    end
    assert_match /Invalid URL/, error.message
  end

  test "CreateUrl rejects missing protocol" do
    error = assert_raises(ArgumentError) do
      Shortener::CreateUrl.call(url: "example.com")
    end
    assert_match /Invalid URL/, error.message
  end

  test "CreateUrl fetches page title" do
    result = Shortener::CreateUrl.call(url: "https://example.com")
    assert result[:title]
    # Title might be "No title" if URL doesn't exist, but should be set
  end

  test "CreateUrl generates unique short code" do
    result1 = Shortener::CreateUrl.call(url: "https://example1.com")
    result2 = Shortener::CreateUrl.call(url: "https://example2.com")
    
    assert_not_equal result1[:short_url], result2[:short_url]
  end

  test "CreateUrl returns URL record" do
    result = Shortener::CreateUrl.call(url: "https://example.com")
    assert result[:url].is_a?(Url)
    assert result[:url].persisted?
  end

  test "CreateUrl handles HTTP protocol" do
    result = Shortener::CreateUrl.call(url: "http://example.com")
    assert result[:short_url]
  end

  test "CreateUrl handles HTTPS protocol" do
    result = Shortener::CreateUrl.call(url: "https://example.com")
    assert result[:short_url]
  end

  test "CreateUrl rejects FTP protocol" do
    error = assert_raises(ArgumentError) do
      Shortener::CreateUrl.call(url: "ftp://example.com")
    end
    assert_match /Invalid URL/, error.message
  end

  test "CreateUrl with query parameters" do
    result = Shortener::CreateUrl.call(url: "https://example.com?id=123&name=test")
    assert result[:short_url]
  end

  test "CreateUrl with fragment" do
    result = Shortener::CreateUrl.call(url: "https://example.com#section")
    assert result[:short_url]
  end

  test "CreateUrl handles URL with port" do
    result = Shortener::CreateUrl.call(url: "https://example.com:8080/path")
    assert result[:short_url]
  end
end
