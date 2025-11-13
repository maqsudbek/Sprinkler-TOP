# Nginx Configuration Addition for pgAdmin

## What to Add

Add the following server blocks to your existing `nginx.conf` file. Insert them anywhere in the `http` block, preferably after the existing server blocks for organization.

---

## Server Block to Add

```nginx
#===================================================
# pgAdmin PostgreSQL Management Web Interface
#--------------------------------------------------
server {
    listen 80;
    listen [::]:80;
    server_name pg.iotserver.uz;

    # Redirect HTTP to HTTPS - NO HTTP access allowed
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name pg.iotserver.uz;

    # SSL Certificate Configuration
    ssl_certificate /etc/letsencrypt/live/pg.iotserver.uz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pg.iotserver.uz/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Logging
    access_log /var/log/nginx/pgadmin_access.log combined;
    error_log /var/log/nginx/pgadmin_error.log;

    # Max upload size (for importing large SQL files)
    client_max_body_size 100M;

    # Proxy to pgAdmin container (use container name, NOT localhost)
    location / {
        proxy_pass http://sprinkler_pgadmin:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Script-Name /;
        
        # WebSocket support (for pgAdmin notifications)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Custom error handling
    error_page 502 503 504 /custom_50x.html;

    location = /custom_50x.html {
        root /usr/share/nginx/html;
        internal;
    }

    location = /favicon.ico {
        root /usr/share/nginx/html;
    }
}
```

---

## Important Notes

### ⚠️ Container Name vs localhost

**CRITICAL:** The nginx configuration uses `proxy_pass http://sprinkler_pgadmin:80;` because:

1. Nginx runs **inside its own container**
2. `localhost` inside nginx container is **NOT** the host machine
3. Docker containers communicate via **container names** on the same network
4. `sprinkler_pgadmin` is the name of the pgAdmin container

**DO NOT use:**
- ❌ `http://localhost:5050` - This is wrong for containerized nginx
- ❌ `http://127.0.0.1:5050` - This is wrong for containerized nginx

**MUST use:**
- ✅ `http://sprinkler_pgadmin:80` - Container name and internal port

### 🔒 HTTPS Only

This configuration **only allows HTTPS access**:
- HTTP requests are **immediately redirected** to HTTPS
- No unencrypted access is permitted
- All traffic is secured with SSL/TLS

---

## Where to Insert

Insert the above configuration in the `http {}` block of your `nginx.conf`, after the existing server blocks. For example:

```nginx
http {
    # ... existing configuration ...

    # Existing server blocks (iotserver.uz, speaker.iotserver.uz, etc.)
    # ...

    # ===================================================
    # ADD THE NEW pgAdmin SERVER BLOCKS HERE
    # ===================================================

}
```

---

## DNS Configuration Required

Before accessing via domain, add this DNS record:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | pg | `<your-server-ip>` | 3600 |

Example if your server IP is `123.45.67.89`:
```
Type: A
Name: pg
Value: 123.45.67.89
TTL: 3600
```

---

## SSL Certificate Setup

### Option 1: Get a new certificate for pg.iotserver.uz (Recommended)

```bash
# Obtain SSL certificate specifically for pg.iotserver.uz
sudo certbot --nginx -d pg.iotserver.uz

# Test automatic renewal
sudo certbot renew --dry-run
```

This creates:
- `/etc/letsencrypt/live/pg.iotserver.uz/fullchain.pem`
- `/etc/letsencrypt/live/pg.iotserver.uz/privkey.pem`

### Option 2: Use wildcard certificate (if you have one)

If you already have a wildcard certificate for `*.iotserver.uz`, update the SSL paths:

```nginx
ssl_certificate /etc/letsencrypt/live/iotserver.uz/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/iotserver.uz/privkey.pem;
```

---

## Deployment Steps

### 1. Update DNS
```bash
# Add DNS A record via your DNS provider
# Type: A
# Name: pg
# Value: <your-server-ip>
```

### 2. Update Nginx Configuration
```bash
# Backup existing config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Edit nginx.conf
sudo nano /etc/nginx/nginx.conf

# Add the pgAdmin server blocks from above
```

### 3. Test Nginx Configuration
```bash
# Test for syntax errors
sudo nginx -t

# Expected output:
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 4. Obtain SSL Certificate
```bash
# Get certificate for pg subdomain
sudo certbot --nginx -d pg.iotserver.uz
```

### 5. Reload Nginx
```bash
# Reload nginx to apply changes
sudo systemctl reload nginx

# Or restart if needed
sudo systemctl restart nginx
```

### 6. Verify Service Status
```bash
# Check nginx is running
sudo systemctl status nginx

# Check pgAdmin container is running
docker compose ps sprinkler_pgadmin
```

---

## Testing

### 1. Test HTTP (should redirect to HTTPS)
```bash
curl -I http://pg.iotserver.uz
# Should show: HTTP/1.1 301 Moved Permanently
# Location: https://pg.iotserver.uz/
```

### 2. Test HTTPS
```bash
curl -I https://pg.iotserver.uz
# Should show: HTTP/2 200
```

### 3. Access in Browser
```
https://pg.iotserver.uz
```

You should see the pgAdmin login page. **Note:** HTTP will automatically redirect to HTTPS.

---

## Troubleshooting

### Error: "Address already in use"
```bash
# Check if another process is using port 443
sudo netstat -tulpn | grep :443

# If nginx is already running, reload instead of restart
sudo systemctl reload nginx
```

### Error: "Certificate not found"
Make sure you ran certbot AFTER adding the server block to nginx.conf:
```bash
sudo certbot --nginx -d pg.iotserver.uz
```

### Error: 502 Bad Gateway

**Possible causes:**

1. **pgAdmin container not running:**
```bash
docker compose ps sprinkler_pgadmin

# If not running, start it:
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d sprinkler_pgadmin
```

2. **Wrong proxy_pass address:**
Ensure nginx config uses `proxy_pass http://sprinkler_pgadmin:80;` (container name, NOT localhost)

3. **Containers not on same network:**
```bash
# Check nginx container network
docker inspect <nginx_container_name> | grep NetworkMode

# Check pgAdmin is on accessible network
docker network inspect sprinkler_postgres_net
```

If nginx is in a different network, you may need to add `sprinkler_postgres_net` to your nginx container or use an external network configuration.

### Error: "Name or service not known"
DNS not configured correctly:
```bash
# Test DNS resolution
nslookup pg.iotserver.uz

# Should return your server IP
```

---

## Security Considerations

### 1. Firewall Rules
```bash
# Ensure ports 80 and 443 are open
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

### 2. Optional: IP Whitelisting

If you want to restrict access by IP:

```nginx
location / {
    # Allow specific IPs
    allow 203.0.113.0/24;  # Your office network
    allow 198.51.100.5;    # Your home IP
    deny all;              # Deny everyone else
    
    proxy_pass http://localhost:5050;
    # ... rest of proxy config
}
```

### 3. Optional: Basic Authentication

Add an extra layer of security with HTTP basic auth:

```bash
# Install htpasswd utility
sudo apt-get install apache2-utils

# Create password file
sudo htpasswd -c /etc/nginx/.htpasswd pgadmin_user

# Enter password when prompted
```

Then add to nginx location block:

```nginx
location / {
    auth_basic "pgAdmin Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    proxy_pass http://localhost:5050;
    # ... rest of proxy config
}
```

---

## Monitoring

### Check Access Logs
```bash
# Real-time monitoring
sudo tail -f /var/log/nginx/pgadmin_access.log

# Check for errors
sudo tail -f /var/log/nginx/pgadmin_error.log
```

### Check pgAdmin Container Logs
```bash
docker compose logs -f sprinkler_pgadmin
```

---

## Summary

**File to Edit:** `/etc/nginx/nginx.conf`

**What to Add:** pgAdmin server blocks (see above)

**Where to Add:** Inside `http {}` block, after existing server configurations

**DNS Required:** A record: `pg.iotserver.uz` → `<your-server-ip>`

**SSL Setup:** `sudo certbot --nginx -d pg.iotserver.uz`

**After Changes:** `sudo nginx -t && sudo systemctl reload nginx`

**Access URL:** https://pg.iotserver.uz

---

## Complete Checklist

- [ ] DNS A record added for `pg.iotserver.uz`
- [ ] pgAdmin server blocks added to `nginx.conf`
- [ ] Nginx configuration tested: `sudo nginx -t`
- [ ] SSL certificate obtained: `sudo certbot --nginx -d pg.iotserver.uz`
- [ ] Nginx reloaded: `sudo systemctl reload nginx`
- [ ] pgAdmin container running: `docker compose ps`
- [ ] HTTP redirects to HTTPS: `curl -I http://pg.iotserver.uz`
- [ ] HTTPS accessible: `curl -I https://pg.iotserver.uz`
- [ ] Web interface loads in browser: https://pg.iotserver.uz
- [ ] Can login with credentials from `pgadmin/.env`
- [ ] Can connect to PostgreSQL from pgAdmin

If all items are checked, your pgAdmin web interface is successfully deployed! ✅
