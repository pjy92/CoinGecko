# URL Shortener Solution - Technical Documentation

## Short URL Path Solution

### Overview
This URL Shortener uses **Base62 encoding** of sequential database IDs to generate short codes. This approach balances simplicity, scalability, and predictability.

### Algorithm: Base62 Encoding

**Base62 Alphabet:** `0-9, A-Z, a-z` (62 characters)

**Process:**
1. When a URL is created, it's assigned a unique ID by the database (auto-incrementing)
2. The ID is encoded to Base62 using the formula:
   ```
   For ID = 1000:
   1000 ÷ 62 = 16 remainder 8
   16 ÷ 62 = 0 remainder 16
   
   Result: "g8" (Base62 alphabet[16] + alphabet[8])
   ```
3. Decoding reverses the process for lookups

### Example Mapping
| ID | Base62 Code | URL | Clicks |
|----|-------------|-----|--------|
| 1 | `1` | https://google.com | 1 |
| 42 | `g` | https://example.com | 0 |
| 1000 | `g8` | https://youtube.com | 2 |

### Implementation

**File:** `lib/base62.rb`
```ruby
module Base62
  ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  
  def self.encode(number)
    return "0" if number == 0
    result = ""
    while number > 0
      result = ALPHABET[number % 62] + result
      number /= 62
    end
    result
  end
end
```

**Service:** `app/services/shortener/create_url.rb`
```ruby
url_record = Url.create!(original_url: @url, title: title)
short_code = Base62.encode(url_record.id)
url_record.update!(short_code: short_code)
```

---

## Advantages

✅ **Guaranteed Uniqueness:** Base on sequential IDs (no collisions)  
✅ **Compact:** Supports ~3.5 billion URLs within 8-character codes  
✅ **Deterministic:** Same ID always produces same code  
✅ **Efficient:** O(log n) encoding/decoding  
✅ **Sequential:** Early URLs have shorter codes (good UX)

---

## Limitations & Workarounds

### 1. **Sequential Predictability**
**Limitation:** Short codes are predictable (1→"1", 2→"2", 3→"3")
- An attacker can enumerate all URLs by incrementing short codes
- Privacy concern for unlisted/confidential URLs

**Workarounds:**
- **Option A (Current):** Accept as trade-off for simplicity. Use at scale with random token for private URLs
- **Option B:** Add random suffix to Base62 (e.g., "g8_x7k2")
  ```ruby
  short_code = "#{Base62.encode(url_record.id)}_#{SecureRandom.hex(3)}"
  ```
- **Option C:** Use hybrid: Sequential + salted hash
  ```ruby
  short_code = Base62.encode(url_record.id + random_offset)
  ```

### 2. **Maximum Capacity**
**Limitation:** Database auto-increment ID has limits
- PostgreSQL bigint max: ~9.2 × 10^18 (very large)
- In practice, limited by storage/performance

**Workaround:** For extreme scale (billion+ URLs), implement:
- ID sharding across multiple services
- Custom ID generator (Snowflake, UUID-based)

### 3. **ID Collision on Concurrent Creates**
**Limitation:** Multiple simultaneous requests could theoretically conflict

**Workaround:** Already mitigated by:
- PostgreSQL's atomic auto-increment
- Database-level uniqueness constraint on `short_code`

### 4. **URL Reuse Collision**
**Limitation:** Same URL creates multiple short codes

**Example:**
```
https://google.com → short code "g"  (ID 16)
https://google.com → short code "h"  (ID 17)
```

**Workaround:**
```ruby
# Deduplication: Check if URL exists before creating
existing = Url.find_by(original_url: @url)
return { short_url: existing.short_code } if existing
```

---

## Database Design

### Schema Rationale

```sql
CREATE TABLE urls (
  id BIGSERIAL PRIMARY KEY,           -- Auto-increment ID (enables Base62)
  original_url VARCHAR NOT NULL,      -- Target URL
  short_code VARCHAR(15) NOT NULL UNIQUE, -- Base62-encoded ID
  title VARCHAR,                      -- Page title (SEO, UX)
  clicks_count INTEGER DEFAULT 0,    -- Denormalized for performance
  expires_at TIMESTAMP,               -- Optional TTL
  created_at TIMESTAMP
);

CREATE TABLE url_visits (
  id BIGSERIAL PRIMARY KEY,
  url_id BIGINT REFERENCES urls(id), -- FK to URLs
  ip_address INET,                   -- Visitor IP
  country VARCHAR(2),                -- Geolocation
  visited_at TIMESTAMP               -- Visit time
);
```

**Indexes:**
- `urls.short_code` (UNIQUE) - Fast short URL lookups
- `url_visits.url_id` - Fast analytics queries
- `urls.expires_at` - TTL cleanup queries

---

## Scalability Considerations

### Current Capacity
- **Max Short URLs:** ~3.5 × 10^9 (Base62 within 8 chars)
- **Max Concurrency:** Limited by PostgreSQL connection pool (default 5-100)
- **Storage:** ~500 bytes per URL + 200 bytes per visit

### Scaling Strategy (Future)

1. **Read Scaling:** Redis cache for hot URLs
   ```ruby
   short_url = Redis.get("url:#{code}") || Url.find_by(short_code: code)
   ```

2. **Write Scaling:** Async analytics logging
   ```ruby
   UrlVisitJob.perform_later(url_id, ip, country) # Sidekiq
   ```

3. **Horizontal Scaling:** Database replication
   ```
   Primary (writes) → Replicas (analytics reads)
   ```

---

## Security Considerations

### Implemented Protections

✅ **CSRF Protection:** Rails `verify_authenticity_token` (disabled for JSON API)  
✅ **Input Validation:** URL format validation using `URI.parse`  
✅ **Rate Limiting:** Rack::Attack (5 requests/min, 10 creates/hour per IP)  
✅ **SQL Injection:** ActiveRecord parameterized queries  
✅ **XSS Prevention:** Rails auto-escaping in views  

### Potential Vulnerabilities & Mitigations

| Vulnerability | Risk | Mitigation |
|---------------|------|-----------|
| **SSRF** | Malicious URL fetching (title scrape) | Read timeout (5s), HTTP-only protocol check |
| **Open Redirect** | Intentional (feature of shortener) | Log redirects for suspicious patterns |
| **Enumeration** | Predictable codes enable discovery | Random suffix (future), private tokens |
| **Data Leakage** | Analytics visible to anyone | Add authentication to `/analytics/:short_code` |

---

## API Endpoints

### 1. Create Short URL
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}' \
  http://localhost:3000/shorten
```

**Response:**
```json
{
  "short_url": "http://localhost:3000/g",
  "original_url": "https://example.com",
  "title": "Example Domain"
}
```

### 2. Redirect (GET /:short_code)
```bash
curl -L http://localhost:3000/g
# Redirects to https://example.com
# Logs visit analytics
```

### 3. View Analytics (GET /analytics/:short_code)
```bash
curl http://localhost:3000/analytics/g
```

**Response:**
```json
{
  "short_code": "g",
  "original_url": "https://example.com",
  "clicks": 5,
  "visits": [
    {"ip": "::1", "country": "US", "visited_at": "2026-04-21T08:00:00Z"},
    ...
  ]
}
```

---

## Testing

Run tests:
```bash
rails test
```

Coverage includes:
- URL creation & validation
- Short code generation
- Click tracking
- Analytics retrieval
- Error handling

---

## Deployment Checklist

- [ ] Set `Rails.env = production`
- [ ] Configure strong `secret_key_base`
- [ ] Set database pool size for concurrency
- [ ] Enable Redis for caching
- [ ] Configure Sidekiq for async jobs
- [ ] Add authentication to `/analytics`
- [ ] Enable HTTPS/TLS
- [ ] Monitor rate limiting logs
- [ ] Set up database backups

---

## References

- Base62 Encoding: https://en.wikipedia.org/wiki/Base62
- Snowflake IDs: https://github.com/twitter-archive/snowflake/tree/snowflake-2010
- URL Shortener Design: https://github.com/donnemartin/system-design-primer
