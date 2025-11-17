# Quick Start Guide - PostgreSQL & pgAdmin

## ✅ Current Status

Both containers are **RUNNING** and **ACCESSIBLE**:

- **PostgreSQL**: Healthy, port 5432
- **pgAdmin**: Running, port 5050 (accessible locally)

## 🔑 Login Credentials

### pgAdmin Web Interface
- **URL (local)**: http://localhost:5050
- **Email**: `admin@iotserver.uz`
- **Password**: `Z4EPfiMMX2dmq0lDWY2ZXj8zcaWvJKvR+5eNB75fv40=`

### PostgreSQL Database
- **Host**: `sprinkler_postgres` (from containers) or `localhost` (from server)
- **Port**: `5432`
- **Database**: `sprinkler` (main) or `sprinkler_web` (for web apps)
- **Username**: `sprinkler`
- **Password**: `lO/vaaVnTHgWo/LbLFtMKE0yuBZo5dPIrF1mO3/IgKI=`

## 📝 Next Steps

### 1. Configure Nginx for Web Access

Edit your nginx configuration and add the blocks from:
```
pgadmin/NGINX_CONFIG.md
```

Then reload nginx:
```bash
docker exec nginx nginx -s reload
```

### 2. Access pgAdmin

Once nginx is configured, go to:
- **https://pg.iotserver.uz**

Login with the pgAdmin credentials above.

### 3. Connect to Database in pgAdmin

The server "Sprinkler PostgreSQL" is pre-configured. Just:
1. Click on it
2. Enter the PostgreSQL password when prompted
3. Start managing your databases!

## 🛠️ Daily Commands

### Start/Stop Services
```bash
# Start
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d

# Stop (keeps data)
docker compose down

# Restart
docker compose restart
```

### View Logs
```bash
docker logs sprinkler_postgres
docker logs sprinkler_pgadmin
```

### Database Access
```bash
# Via CLI
docker exec -it sprinkler_postgres psql -U sprinkler -d sprinkler

# Via pgAdmin
# Access at http://localhost:5050 or https://pg.iotserver.uz
```

## 📚 Full Documentation

- **Deployment Summary**: `DEPLOYMENT_SUMMARY.md`
- **Nginx Configuration**: `pgadmin/NGINX_CONFIG.md`
- **Project README**: `README.md`

---

**Everything is ready!** Just add the nginx config to enable web access. 🚀
