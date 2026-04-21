# README
## Link Shortener API (Rails)
A lightweight URL shortener service built with Ruby on Rails that supports URL shortening, redirection, click tracking, and analytics.

## Features
Shorten long URLs into unique short codes
Redirect short URLs to original destinations
Track total click counts per URL
Record detailed visit analytics (IP, country, timestamp)
Analytics API for reporting usage statistics

## Tech Stack
Ruby on Rails 7.2
PostgreSQL
Geocoder (IP  country resolution)

## Setup Instructions
bundle install
rails db:create
rails db:migrate
rails server

Server runs at:
http://localhost:3000

## API Endpoints
1. Create Short URL
Create a shortened version of a long URL.
POST /shorten
Content-Type: application/json

Request:
{
  "original_url": "https://example.com"
}

Response:
{
  "short_code": "abc123",
  "original_url": "https://example.com"
}

2. Redirect Short URL
Redirects user to original URL and logs analytics.
GET /:short_code

Example:
http://localhost:3000/abc123

Behavior:
Redirects to original URL
Increments click counter
Logs visit (IP, country, timestamp)

3. Analytics Endpoint
Retrieve usage analytics for a short URL.
GET /analytics/:short_code

Response:
{
  "short_code": "abc123",
  "original_url": "https://example.com",
  "clicks": 10,
  "visits": [
    {
      "ip": "127.0.0.1",
      "country": "Malaysia",
      "visited_at": "2026-04-21T07:00:00Z"
    }
  ]
}

## Design Decisions
Click tracking
Stored in database (clicks_count) for performance efficiency
 
Visit logging
Each redirect stores:
IP address
Country (via Geocoder)
Timestamp

Data consistency
Associations:
Url has_many :url_visits
UrlVisit belongs_to :url

## Database Schema
Url
Field      	Type
id	        integer
original_url	string
short_code	string
clicks_count	integer
created_at	datetime

UrlVisit
Field	        Type
id	        integer
url_id     	integer
ip_address	string
country	        string
visited_at	datetime

## Example Usage (curl)
Create URL
curl -X POST http://localhost:3000/shorten \
-H "Content-Type: application/json" \
-d '{"original_url":"https://google.com"}'

Access Short URL
curl -i http://localhost:3000/abc123

View Analytics
curl http://localhost:3000/analytics/abc123

## Assumptions
Short codes are unique
Geolocation may fallback if IP resolution fails
Local requests (::1) mapped to test IP for country lookup

## Summary
This project demonstrates:
RESTful API design
Database relationships
Request lifecycle handling
Basic analytics tracking
External service integration (Geocoder)
