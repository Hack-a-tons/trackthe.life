# Wildcard Certificate for *.hurated.com

## Current Status

The `*.hurated.com` wildcard certificate expired on **October 25, 2025**.

This certificate is used by the bot sharing feature (wildcard subdomain routing).

---

## Renewal Steps

### 1. Request New Certificate

```bash
ssh trackthelife.hurated.com 'cd nginx-host && docker compose exec nginx certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d "*.hurated.com" \
  --agree-tos \
  --email dbystruev@gmail.com \
  --manual-public-ip-logging-ok'
```

### 2. Add DNS TXT Record

The command will show you something like:

```
Please deploy a DNS TXT record under the name:
_acme-challenge.hurated.com.

with the following value:
7dIImQhOmkWG_zfxlMiT1TBujSdKs5dNUNE0RMw0iWY
```

**Go to your DNS provider** (wherever hurated.com is hosted) and add:

```
Type: TXT
Name: _acme-challenge
Host: hurated.com
Value: <the value shown by certbot>
TTL: 300
```

### 3. Verify DNS Record

Before pressing Enter in certbot, verify the record is live:

```bash
dig TXT _acme-challenge.hurated.com +short
```

You should see the value you added.

Or use: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.hurated.com

### 4. Complete Certificate Request

Once DNS is verified, press **Enter** in the certbot prompt.

Certbot will:
- Verify the DNS record
- Issue the certificate
- Save it to `/etc/letsencrypt/live/hurated.com/`

### 5. Re-enable Wildcard Config

```bash
ssh trackthelife.hurated.com 'cd nginx-host && \
  docker compose exec nginx mv /etc/nginx/conf.d/wildcard.hurated.com.conf.disabled /etc/nginx/conf.d/wildcard.hurated.com.conf && \
  docker compose exec nginx nginx -t && \
  docker compose exec nginx nginx -s reload'
```

### 6. Test

```bash
curl -I https://anybot.hurated.com
```

Should return 200 OK with valid SSL.

---

## Automatic Renewal (Recommended)

Manual DNS validation requires repeating these steps every 90 days. For automatic renewal, use a DNS plugin.

### Option 1: Cloudflare DNS Plugin

If hurated.com uses Cloudflare:

```bash
# Install plugin
docker compose exec nginx pip install certbot-dns-cloudflare

# Create credentials file
cat > cloudflare.ini << EOF
dns_cloudflare_api_token = your_cloudflare_api_token
EOF

# Request certificate with auto-renewal
docker compose exec nginx certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /path/to/cloudflare.ini \
  -d "*.hurated.com" \
  --agree-tos \
  --email dbystruev@gmail.com
```

### Option 2: Route53 DNS Plugin

If hurated.com uses AWS Route53:

```bash
# Install plugin
docker compose exec nginx pip install certbot-dns-route53

# Configure AWS credentials
docker compose exec nginx certbot certonly \
  --dns-route53 \
  -d "*.hurated.com" \
  --agree-tos \
  --email dbystruev@gmail.com
```

### Option 3: Other DNS Providers

Certbot supports many DNS providers:
- certbot-dns-google (Google Cloud DNS)
- certbot-dns-digitalocean
- certbot-dns-azure
- certbot-dns-namecheap
- And many more...

See: https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins

---

## Wildcard Config Details

**File**: `/etc/nginx/conf.d/wildcard.hurated.com.conf`

**Purpose**: Routes any subdomain (except existing ones) to bot sharing feature

**Excluded subdomains**:
- app.hurated.com
- app.dev.hurated.com
- app.stage.hurated.com
- api.hurated.com
- ai.hurated.com
- back.hurated.com
- aws.hurated.com
- ghost.hurated.com
- trackthelife.hurated.com (has its own config)

**Routes to**: http://localhost:5000 (bot sharing backend)

---

## Current Certificate Status

All other certificates are valid and auto-renewing:

- ✅ trackthelife.hurated.com - Expires 2026-02-02 (89 days)
- ✅ ai.hurated.com - Expires 2025-12-20 (45 days)
- ✅ api.hurated.com - Expires 2025-12-07 (32 days)
- ✅ app.hurated.com - Expires 2026-01-22 (78 days)
- ✅ app.stage.hurated.com - Expires 2025-12-14 (39 days)
- ✅ aws.hurated.com - Expires 2026-01-19 (75 days)
- ✅ ghost.hurated.com - Expires 2026-01-20 (76 days)
- ❌ *.hurated.com - EXPIRED (Oct 25, 2025)

---

## Quick Commands

**Check certificate**:
```bash
echo | openssl s_client -servername trackthelife.hurated.com -connect trackthelife.hurated.com:443 2>/dev/null | openssl x509 -noout -dates -subject
```

**List all certificates**:
```bash
ssh trackthelife.hurated.com 'cd nginx-host && docker compose exec nginx certbot certificates'
```

**Test nginx config**:
```bash
ssh trackthelife.hurated.com 'cd nginx-host && docker compose exec nginx nginx -t'
```

**Reload nginx**:
```bash
ssh trackthelife.hurated.com 'cd nginx-host && docker compose exec nginx nginx -s reload'
```
