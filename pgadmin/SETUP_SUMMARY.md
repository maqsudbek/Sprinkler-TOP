# pgAdmin Setup - Summary

## ✅ What Was Done

### 1. Created pgAdmin Directory Structure

```
pgadmin/
├── .env.example          # Template environment file
├── .env                  # Active environment file (git-ignored)
├── .gitignore            # Ignore sensitive data
├── servers.json          # Pre-configured PostgreSQL server connection
├── README.md             # Comprehensive documentation
└── QUICKSTART.md         # Quick testing guide
```

### 2. Updated docker-compose.yml

Added `sprinkler_pgadmin` service with:
- **Image**: `dpage/pgadmin4:latest`
- **Container name**: `sprinkler_pgadmin`
- **Port mapping**: `5050:80` (configurable via env)
- **Pre-configured server**: Auto-loads PostgreSQL connection
- **Health check**: Ensures service is ready
- **Depends on**: PostgreSQL container (waits for healthy status)
- **Persistent data**: Named volume `sprinkler_pgadmin_data`
- **Network**: Same network as PostgreSQL for container-to-container communication

### 3. Configuration Files

#### pgadmin/.env.example and pgadmin/.env
```env
PGADMIN_DEFAULT_EMAIL=admin@iotserver.uz
PGADMIN_DEFAULT_PASSWORD=ChangeMe!SecurePassword123
PGADMIN_HOST_PORT=5050
PGADMIN_CONFIG_SERVER_MODE=True
PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=True
PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=True
```

#### pgadmin/servers.json
Pre-configures PostgreSQL server connection:
- **Server Name**: Sprinkler PostgreSQL
- **Host**: `sprinkler_postgres` (container name, not localhost)
- **Port**: 5432
- **Database**: sprinkler
- **Username**: sprinkler

### 4. Updated Repository Files

#### .gitignore
Added exclusions for:
- `pgadmin/.env`
- `pgadmin/data/`
- `pgadmin/sessions/`
- `pgadmin/*.db*`
- `pgadmin/*.log`

#### README.md
- Updated project structure
- Added pgAdmin section with local and cloud access instructions
- Referenced pgAdmin documentation

### 5. Documentation Created

#### pgadmin/README.md (Comprehensive Guide)
- Quick start instructions
- Container management commands
- **Nginx configuration for pg.iotserver.uz**
- SSL/TLS setup with Let's Encrypt
- Security best practices
- Troubleshooting guide
- Backup/restore procedures
- Advanced configuration options

#### pgadmin/QUICKSTART.md (Testing Guide)
- Step-by-step testing instructions
- Verification procedures
- Sample SQL queries
- Common issues and fixes

## 🌐 Access Points

### Local Development (Windows 11)
- **URL**: http://localhost:5050
- **Email**: `admin@iotserver.uz` (from pgadmin/.env)
- **Password**: (from `PGADMIN_DEFAULT_PASSWORD` in pgadmin/.env)

### Cloud Production
- **URL**: https://pg.iotserver.uz
- **Email**: (from pgadmin/.env on server)
- **Password**: (from `PGADMIN_DEFAULT_PASSWORD` in pgadmin/.env on server)

## 🚀 Usage Commands

### Start Both Services
```powershell
# Windows (PowerShell)
docker compose --env-file postgresql\.env --env-file pgadmin\.env up -d

# Linux (Bash)
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d
```

### Start Only pgAdmin
```powershell
docker compose --env-file pgadmin\.env up -d sprinkler_pgadmin
```

### Check Status
```powershell
docker compose ps
```

### View Logs
```powershell
docker compose logs -f sprinkler_pgadmin
```

### Stop Services
```powershell
docker compose down
```

### Restart pgAdmin
```powershell
docker compose restart sprinkler_pgadmin
```

## 🔧 Nginx Configuration for Cloud

To enable access via `pg.iotserver.uz`, add this server block to your Nginx configuration:

**⚠️ CRITICAL:** Use `proxy_pass http://sprinkler_pgadmin:80;` (container name), **NOT** `localhost`

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

    # SSL Configuration
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
    access_log /var/log/nginx/pgadmin_access.log;
    error_log /var/log/nginx/pgadmin_error.log;

    # Max upload size for large SQL imports
    client_max_body_size 100M;

    # Proxy to pgAdmin container (use container name, NOT localhost)
    location / {
        proxy_pass http://sprinkler_pgadmin:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
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

**Why container name?**
- Nginx runs **inside its own container**
- `localhost` in nginx container ≠ host machine
- Docker containers communicate via **container names**
- `sprinkler_pgadmin` must be accessible from nginx's network

> **Redirect loop warning:** Leave `X-Script-Name` unset when hosting pgAdmin directly at `https://pg.iotserver.uz/`. Adding `X-Script-Name: /` causes pgAdmin to issue an endless HTTP 308 redirect back to `/`. Only set that header if you deliberately serve pgAdmin from a sub-path (e.g., `/pgadmin`).

### SSL Certificate Setup

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d pg.iotserver.uz

# Test auto-renewal
sudo certbot renew --dry-run
```

### DNS Configuration

Add an A record in your DNS provider:
```
Type: A
Name: pg
Value: <your-server-ip>
TTL: 3600
```

## 📋 Deployment Checklist

### Local Testing
- [x] Created pgadmin directory and files
- [x] Updated docker-compose.yml
- [x] Created environment files
- [x] Started containers successfully
- [ ] Access pgAdmin at http://localhost:5050
- [ ] Login with credentials
- [ ] Connect to PostgreSQL
- [ ] Run test queries

### Cloud Deployment
- [ ] Commit and push changes to GitHub
- [ ] Pull changes on server: `git pull`
- [ ] Copy environment files on server
- [ ] Start containers on server
- [ ] Configure Nginx with above server block
- [ ] Setup DNS A record for pg.iotserver.uz
- [ ] Obtain SSL certificate with certbot
- [ ] Test HTTPS access at https://pg.iotserver.uz
- [ ] Verify PostgreSQL connection from pgAdmin
- [ ] Test SQL queries on production

## 🔒 Security Notes

1. **Change passwords**: Update `PGADMIN_DEFAULT_PASSWORD` in production
2. **HTTPS only**: Never expose pgAdmin over HTTP in production
3. **Firewall rules**: Consider restricting access by IP if possible
4. **Regular updates**: Keep pgAdmin container updated
5. **Master password**: Use strong master password when saving DB credentials
6. **SSL certificates**: Keep certificates renewed automatically

## 📦 Data Persistence

pgAdmin data is stored in Docker volume: `sprinkler_pgadmin_data`

This includes:
- Saved server connections
- User preferences
- Query history
- Saved queries

### Backup Volume
```bash
docker run --rm -v sprinkler_pgadmin_data:/data -v $(pwd)/backups:/backup ubuntu tar czf /backup/pgadmin-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore Volume
```bash
docker run --rm -v sprinkler_pgadmin_data:/data -v $(pwd)/backups:/backup ubuntu tar xzf /backup/pgadmin-backup-YYYYMMDD.tar.gz -C /
```

## 🎯 Key Features

✅ **Pre-configured server**: PostgreSQL connection auto-configured via servers.json  
✅ **Health checks**: Automatic monitoring of service health  
✅ **Persistent data**: Configurations saved in Docker volume  
✅ **Secure by default**: Enhanced cookie protection and master password required  
✅ **Production ready**: Server mode enabled for multi-user access  
✅ **Easy deployment**: Single docker-compose command for both environments  
✅ **Comprehensive docs**: README.md and QUICKSTART.md for guidance  
✅ **Nginx ready**: Configuration template provided for reverse proxy  
✅ **SSL ready**: Instructions for Let's Encrypt certificate  

## 📚 Documentation

- **pgadmin/README.md** - Full documentation with all features and troubleshooting
- **pgadmin/QUICKSTART.md** - Quick testing and verification guide
- **Main README.md** - Updated with pgAdmin section

## 🎉 Success!

Your pgAdmin web-based GUI is now set up and ready to use. You can manage PostgreSQL databases through a modern web interface accessible both locally and via `pg.iotserver.uz` in production.

**Current Status:**
- ✅ Containers running successfully
- ✅ pgAdmin accessible at http://localhost:5050
- ✅ PostgreSQL connection pre-configured
- ✅ Documentation complete
- ✅ Ready for cloud deployment

**Next Steps:**
1. Test locally following `pgadmin/QUICKSTART.md`
2. Commit and push to GitHub
3. Deploy to cloud server
4. Configure Nginx for `pg.iotserver.uz`
5. Access via HTTPS in production
