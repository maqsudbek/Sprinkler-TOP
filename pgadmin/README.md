# pgAdmin - Web-based PostgreSQL Management

This directory contains the configuration for pgAdmin, a web-based GUI tool for managing PostgreSQL databases.

## Quick Start

### 1. Configure Environment

Copy the example environment file and customize:

```bash
cp .env.example .env
```

Edit `.env` and change:
- `PGADMIN_DEFAULT_EMAIL` - Your login email
- `PGADMIN_DEFAULT_PASSWORD` - Strong password for pgAdmin login
- `PGADMIN_HOST_PORT` - Port to access pgAdmin (default: 5050)

### 2. Start pgAdmin

From the repository root:

```bash
docker compose up -d sprinkler_pgadmin
```

Or start both PostgreSQL and pgAdmin together:

```bash
docker compose up -d
```

### 3. Access pgAdmin

**Local Access (Development):**
- URL: http://localhost:5050
- Email: (value from `PGADMIN_DEFAULT_EMAIL`)
- Password: (value from `PGADMIN_DEFAULT_PASSWORD`)

**Cloud Access (Production - HTTPS Only):**
- URL: https://pg.iotserver.uz
- Email: (value from `PGADMIN_DEFAULT_EMAIL`)
- Password: (value from `PGADMIN_DEFAULT_PASSWORD`)
- **Note:** HTTP requests are automatically redirected to HTTPS for security

### 4. Connect to PostgreSQL

The PostgreSQL server is pre-configured in pgAdmin (from `servers.json`). When you first expand the server:

1. Click on **"Sprinkler PostgreSQL"** in the left sidebar
2. Enter the PostgreSQL password: `G7f$2kL9pQw!xZrT` (or your custom password from `postgresql/.env`)
3. Optionally check **"Save password"** for convenience

## Container Management

### Check Status

```bash
docker compose ps sprinkler_pgadmin
```

### View Logs

```bash
docker compose logs -f sprinkler_pgadmin
```

### Restart pgAdmin

```bash
docker compose restart sprinkler_pgadmin
```

### Stop pgAdmin

```bash
docker compose stop sprinkler_pgadmin
```

### Remove Container (keeps data)

```bash
docker compose down sprinkler_pgadmin
```

## Cloud Deployment (Nginx Configuration)

To access pgAdmin at `pg.iotserver.uz`, add this configuration to your Nginx config.

**⚠️ IMPORTANT:** 
- Use container name `sprinkler_pgadmin:80` in `proxy_pass`, **NOT** `localhost:5050`
- Nginx runs in its own container, so `localhost` refers to the nginx container itself
- Only HTTPS access is allowed; HTTP redirects to HTTPS

### Add to existing nginx.conf

```nginx
# pgAdmin Web Interface - HTTPS Only
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
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Logging
    access_log /var/log/nginx/pgadmin_access.log;
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
}
```

### SSL Certificate Setup

Before accessing via HTTPS, obtain an SSL certificate using Let's Encrypt:

```bash
# Install certbot if not already installed
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate for pg.iotserver.uz
sudo certbot --nginx -d pg.iotserver.uz

# Test automatic renewal
sudo certbot renew --dry-run
```

### DNS Configuration

Ensure your DNS has an A record pointing to your server:

```
Type: A
Name: pg
Value: <your-server-ip>
TTL: 3600
```

## Data Persistence

pgAdmin data is stored in a named Docker volume: `sprinkler_pgadmin_data`

This includes:
- Saved server connections
- User preferences
- Query history
- Saved queries

### Backup pgAdmin Configuration

```bash
# Backup the volume
docker run --rm -v sprinkler_pgadmin_data:/data -v $(pwd)/backups:/backup ubuntu tar czf /backup/pgadmin-backup-$(date +%Y%m%d-%H%M%S).tar.gz /data
```

### Restore pgAdmin Configuration

```bash
# Restore from backup
docker run --rm -v sprinkler_pgadmin_data:/data -v $(pwd)/backups:/backup ubuntu tar xzf /backup/pgadmin-backup-YYYYMMDD-HHMMSS.tar.gz -C /
```

## Security Considerations

1. **Change Default Password**: Always change `PGADMIN_DEFAULT_PASSWORD` in production
2. **Use HTTPS**: Only expose pgAdmin over HTTPS in production
3. **Restrict Access**: Consider IP whitelisting in Nginx for sensitive environments
4. **Regular Updates**: Keep pgAdmin container updated with latest security patches
5. **Strong Master Password**: When saving database passwords, use a strong master password

## Troubleshooting

### Cannot Access pgAdmin

1. Check if container is running:
   ```bash
   docker compose ps sprinkler_pgadmin
   ```

2. Check logs for errors:
   ```bash
   docker compose logs sprinkler_pgadmin
   ```

3. Verify port is not in use:
   ```bash
   netstat -ano | findstr :5050
   ```

### Cannot Connect to PostgreSQL

1. Ensure PostgreSQL container is running:
   ```bash
   docker compose ps sprinkler_postgres
   ```

2. Verify both containers are on the same network:
   ```bash
   docker network inspect sprinkler_network
   ```

3. Use hostname `sprinkler_postgres` (not `localhost`) when connecting from pgAdmin

### Permission Errors

If you encounter permission errors with volumes:

```bash
# Stop containers
docker compose down

# Remove volume and recreate
docker volume rm sprinkler_pgadmin_data
docker compose up -d sprinkler_pgadmin
```

## Advanced Configuration

### Custom Configuration File

You can mount a custom pgAdmin config file by creating `config_local.py` and updating the docker-compose.yml:

```python
# config_local.py example
CONSOLE_LOG_LEVEL = 'WARNING'
FILE_LOG_LEVEL = 'WARNING'
DEFAULT_QUERY_TOOL_TAB_COUNT = 3
```

### Environment Variables

Additional pgAdmin configuration options:

- `PGADMIN_LISTEN_ADDRESS` - Listen address (default: 0.0.0.0)
- `PGADMIN_LISTEN_PORT` - Listen port inside container (default: 80)
- `PGADMIN_ENABLE_TLS` - Enable TLS (default: False)
- `PGADMIN_CONFIG_*` - Any pgAdmin config setting

See [pgAdmin Docker Documentation](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html) for more options.

## Version Information

- **pgAdmin Version**: Latest (actual version depends on the image at pull time)
- **Python**: 3.11
- **Base Image**: dpage/pgadmin4:latest

## Support

For pgAdmin-specific issues, consult:
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [pgAdmin Docker Hub](https://hub.docker.com/r/dpage/pgadmin4/)
- [pgAdmin GitHub Issues](https://github.com/pgadmin-org/pgadmin4/issues)
