# Nginx Configuration for pgAdmin

This document contains the nginx configuration blocks to add to your main nginx.conf file to make pgAdmin accessible at `https://pg.iotserver.uz`.

## Configuration Blocks to Add

Add these two server blocks to your nginx.conf file in the `http` section:

### HTTPS Server Block (Port 443)

```nginx
#===================================================
# PG.iotserver.uz - pgAdmin PostgreSQL Web Interface
#--------------------------------------------------
server {
    listen 443 ssl;
    # http2 on;
    server_name pg.iotserver.uz;

    ssl_certificate /etc/letsencrypt/live/iotserver.uz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/iotserver.uz/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;

   location / {
      proxy_pass http://sprinkler_pgadmin:80;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_redirect off;
        
        # Increase timeouts for long-running queries
        proxy_connect_timeout 300s;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    error_page 502 503 504 =501 /custom_50x;

    location = /custom_50x {
        return 501;
    }

    location = /favicon.ico {
        root /usr/share/nginx/html;
    }
}
```

### HTTP Server Block (Port 80) - Redirects to HTTPS

```nginx
#--------------------------------------------------
server {
    listen 80;
    server_name pg.iotserver.uz;

    # Redirect all HTTP to HTTPS
    return 301 https://$host$request_uri;
}
```

## Important Notes

1. **Container Network**: The configuration uses `proxy_pass http://sprinkler_pgadmin:80;` because:
   - Both nginx and sprinkler_pgadmin are on the `mynetwork` Docker network
   - Docker's internal DNS resolves container names
   - DO NOT use `localhost:5050` as that won't work from inside the nginx container

2. **Timeouts**: pgAdmin may execute long-running database queries, so increased timeout values (300s) are set

3. **No `X-Script-Name` Header**: Do **not** set `X-Script-Name` to `/` for root deployments. pgAdmin interprets that header as an additional URL prefix and responds with a 308 redirect loop back to `/`. Only send `X-Script-Name` if you intentionally mount pgAdmin under a sub-path (e.g., `/pgadmin`).

3. **SSL Redirect**: All HTTP traffic on port 80 automatically redirects to HTTPS

## Steps to Apply

1. **Edit your main nginx configuration**:
   ```bash
   nano /etc/nginx/nginx.conf
   # Or wherever your nginx.conf is located
   ```

2. **Add the server blocks** from above to the `http` section

3. **Test the configuration**:
   ```bash
   docker exec nginx nginx -t
   ```

4. **Reload nginx** if test passes:
   ```bash
   docker exec nginx nginx -s reload
   ```

## Access Information

- **URL**: https://pg.iotserver.uz
- **Login Email**: admin@iotserver.uz
- **Login Password**: See `pgadmin/.env` file

## Troubleshooting

If you can't access pgAdmin after adding the config:

1. **Check nginx logs**:
   ```bash
   docker logs nginx
   ```

2. **Verify pgAdmin is healthy**:
   ```bash
   docker compose ps
   ```

3. **Test container connectivity**:
   ```bash
   docker exec nginx ping sprinkler_pgadmin
   ```

4. **Check DNS resolution**:
   ```bash
   docker exec nginx nslookup sprinkler_pgadmin
   ```
