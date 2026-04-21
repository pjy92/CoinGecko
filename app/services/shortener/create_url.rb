require 'uri'
require 'securerandom'
require 'open-uri'
require 'nokogiri'
require_relative '../../../lib/base62'

module Shortener
  class CreateUrl
    def self.call(url:)
      new(url).call
    end

    def initialize(url)
      @url = url
    end

    def call
      validate_url!(@url)

      title = fetch_title(@url)

      # Generate a temporary unique short_code
      temp_code = SecureRandom.alphanumeric(10)

      url_record = Url.create!(
        original_url: @url,
        title: title,
        short_code: temp_code
      )

      # Generate short_code based on ID
      short_code = Base62.encode(url_record.id)
      url_record.update!(short_code: short_code)

      { short_url: short_code, title: title, url: url_record }
    end

    private

    def validate_url!(url)
      uri = URI.parse(url)
      raise ArgumentError, "Invalid URL" unless uri.is_a?(URI::HTTP) && uri.host
    end

    def fetch_title(url)
      html = URI.open(url, read_timeout: 5)
      doc = Nokogiri::HTML(html)
      doc.at('title')&.text&.strip || "No title"
    rescue StandardError
      "No title"
    end
  end
end
