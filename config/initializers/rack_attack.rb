class Rack::Attack
  # Throttle requests to 5 per minute per IP
  throttle('req/ip', limit: 5, period: 1.minute) do |req|
    req.ip
  end

  # Throttle URL creation to 10 per hour per IP
  throttle('urls/ip', limit: 10, period: 1.hour) do |req|
    req.ip if req.path == '/shorten' && req.post?
  end

  # Block suspicious requests
  blocklist('block_bad_ips') do |req|
    # Add IPs to block if needed
    false
  end
end
