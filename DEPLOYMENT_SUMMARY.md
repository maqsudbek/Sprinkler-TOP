# PostgreSQL & pgAdmin Deployment Summary

**Date**: November 17, 2025  
**Server**: vmi1595621 (Debian Linux)  
**Project**: Sprinkler IoT Infrastructure

---

## 🎯 What Was Accomplished

Successfully deployed PostgreSQL 16 and pgAdmin 4 in Docker containers with:
- ✅ Persistent data storage (survives container restarts)
- ✅ Secure random passwords generated
- ✅ Connected to existing `mynetwork` for nginx access
- ✅ Health checks configured
- ✅ Pre-configured database server connection in pgAdmin

---

## 📋 Deployment Steps Completed

### 1. Created Environment Files
- **postgresql/.env** - Database credentials and configuration
- **pgadmin/.env** - Admin interface credentials

### 2. Updated docker-compose.yml
- Added `mynetwork` as external network
- Connected both containers to `mynetwork` for nginx reverse proxy
- Kept internal `sprinkler_postgres_net` for container-to-container communication

### 3. Started Containers
```bash
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d
```

**Result**:
- `sprinkler_postgres` - Running, healthy
- `sprinkler_pgadmin` - Running, accessible on port 5050

---

## 🔐 Generated Credentials

### PostgreSQL Database
- **Database**: `sprinkler`
- **Username**: `sprinkler`
- **Password**: `lO/vaaVnTHgWo/LbLFtMKE0yuBZo5dPIrF1mO3/IgKI=`
- **Port**: 5432 (mapped to host)

### Additional Databases (auto-created)
- **sprinkler_web** - Created by initdb script with uuid-ossp and pgcrypto extensions

### pgAdmin Web Interface
- **Login Email**: `admin@iotserver.uz`
- **Password**: `Z4EPfiMMX2dmq0lDWY2ZXj8zcaWvJKvR+5eNB75fv40=`
- **Local Access**: http://localhost:5050 (from server)

---

## 📂 Data Persistence

All data is stored in persistent volumes and will survive container restarts:

### PostgreSQL Data
- **Location**: `./postgresql/data` (bind mount)
- **Contains**: All databases, tables, and data
- **Backup Location**: `./postgresql/backups` (manually managed)

### pgAdmin Configuration
- **Volume**: `sprinkler_pgadmin_data` (Docker named volume)
- **Contains**: User preferences, saved queries, server connections

---

## 🌐 Network Configuration

Both containers are connected to two networks:

1. **sprinkler_postgres_net** (internal)
   - For PostgreSQL ↔ pgAdmin communication
   - Bridge network created by this compose file

2. **mynetwork** (external)
   - Shared with nginx, mysql, phpmyadmin, and other services
   - Allows nginx to proxy requests to pgAdmin
   - Container names resolve via Docker DNS

---

## 🔜 Next Steps

### To Enable Web Access via nginx

1. **Add nginx configuration** for `pg.iotserver.uz`:
   - See detailed instructions in: `pgadmin/NGINX_CONFIG.md`
   - Add the provided server blocks to your nginx.conf

2. **Test nginx configuration**:
   ```bash
   docker exec nginx nginx -t
   ```

3. **Reload nginx**:
   ```bash
   docker exec nginx nginx -s reload
   ```

4. **Access pgAdmin**:
   - URL: https://pg.iotserver.uz
   - Login with credentials from `pgadmin/.env`

### First Login to pgAdmin

1. Go to https://pg.iotserver.uz (after nginx is configured)
2. Login with `admin@iotserver.uz` and the pgAdmin password
3. Server "Sprinkler PostgreSQL" should be pre-configured (from `servers.json`)
4. Click the server and enter the PostgreSQL password when prompted

---

## 🛠️ Useful Commands

### Check Container Status
```bash
docker compose ps
```

### View Logs
```bash
# PostgreSQL logs
docker logs sprinkler_postgres

# pgAdmin logs
docker logs sprinkler_pgadmin

# Follow logs in real-time
docker logs -f sprinkler_postgres
```

### Restart Services
```bash
docker compose restart
```

### Stop Services (keeps data)
```bash
docker compose down
```

### Start Services Again
```bash
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d
```

### Access PostgreSQL CLI
```bash
docker exec -it sprinkler_postgres psql -U sprinkler -d sprinkler
```

### Create Database Backup
```bash
docker exec sprinkler_postgres pg_dump -U sprinkler -Fc sprinkler_web -f /backups/sprinkler_web_$(date +%Y%m%d).dump
```

Backup will be saved in `./postgresql/backups/` on the host.

---

## 📁 File Structure

```
/home/maqsud/sprinkler/
├── docker-compose.yml          # Updated with mynetwork
├── postgresql/
│   ├── .env                    # ⚠️ KEEP SECURE - Database credentials
│   ├── data/                   # Persistent database storage
│   ├── backups/                # Manual backup location
│   └── initdb/
│       └── 001-create-databases.sql  # Auto-runs on first start
├── pgadmin/
│   ├── .env                    # ⚠️ KEEP SECURE - Admin credentials
│   ├── servers.json            # Pre-configured DB connection
│   ├── NGINX_CONFIG.md         # Nginx setup instructions (this file)
│   └── DEPLOYMENT_SUMMARY.md   # This summary document
```

---

## ⚠️ Security Notes

1. **Never commit .env files** to version control (already in .gitignore)
2. **Passwords are auto-generated** with cryptographic randomness (32 bytes base64)
3. **SSL enforced** via nginx (HTTP redirects to HTTPS)
4. **Master password required** in pgAdmin for saving server passwords
5. **Database not exposed** to internet (only accessible via pgAdmin or localhost)

---

## 🔍 Verification Checklist

- [x] PostgreSQL container running and healthy
- [x] pgAdmin container running
- [x] Both containers on mynetwork (verified with `docker network inspect mynetwork`)
- [x] Database files created in `postgresql/data/`
- [x] `sprinkler_web` database created with extensions
- [ ] Nginx configured for pg.iotserver.uz (manual step required)
- [ ] Web access tested at https://pg.iotserver.uz (after nginx config)

---

## 📞 Troubleshooting

### Container won't start
```bash
# Check logs for errors
docker compose logs

# Verify env files exist and are readable
ls -la postgresql/.env pgadmin/.env
```

### Can't connect to database
```bash
# Test from host
docker exec -it sprinkler_postgres psql -U sprinkler -d sprinkler

# Check if database is accepting connections
docker exec sprinkler_postgres pg_isready -U sprinkler
```

### pgAdmin can't reach PostgreSQL
```bash
# Both containers should be on the same network
docker network inspect sprinkler_postgres_net

# Test DNS resolution
docker exec sprinkler_pgadmin ping sprinkler_postgres
```

### Lost credentials
```bash
# View PostgreSQL password
cat postgresql/.env | grep POSTGRES_PASSWORD

# View pgAdmin password
cat pgadmin/.env | grep PGADMIN_DEFAULT_PASSWORD
```

---

## 📚 References

- PostgreSQL Docker Image: https://hub.docker.com/_/postgres
- pgAdmin Docker Image: https://hub.docker.com/r/dpage/pgadmin4
- Project README: `README.md`
- Nginx Configuration: `pgadmin/NGINX_CONFIG.md`

---

**Status**: ✅ Deployment Complete - Ready for nginx configuration
