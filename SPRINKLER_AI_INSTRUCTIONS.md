# Sprinkler IoT - AI Coding Agent Instructions

## Project Overview

This is the **top-level infrastructure repository** for the Sprinkler IoT project, managing PostgreSQL database and pgAdmin services via Docker Compose. The actual application logic lives in **separate repositories** (webapi and webota) that are excluded from this repo but deployed to the same server directory (`/home/maqsud/sprinkler`).

**Key Architecture Pattern:**
- This repo: Infrastructure only (database, pgAdmin, deployment configs)
- `webapi/`: [Separate repo](https://github.com/maqsudbek/Sprinkler-webAPI) - FastAPI backend with SQLAlchemy
- `webota/`: [Separate repo](https://github.com/maqsudbek/Sprinkler-webOTA) - OTA firmware updates service
- All three deploy to the same directory on the server but are version-controlled independently

## Critical Developer Workflows

### Environment Setup (First-Time)

**Windows 11 Development:**
```powershell
# 1. Copy environment templates
Copy-Item postgresql/.env.example postgresql/.env
Copy-Item pgadmin/.env.example pgadmin/.env

# 2. Edit .env files with strong passwords

# 3. Start services (Docker Desktop must be running)
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d

# 4. Verify health
docker compose ps
```

**Cloud Server Deployment:**
```bash
# Services auto-deploy via GitHub Actions on push to main
# Manual deployment if needed:
cd /home/maqsud/sprinkler
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d
```

### Working with Docker Compose

**ALWAYS use env files** - credentials are never in docker-compose.yml:
```bash
# Start all services
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d

# Start specific service
docker compose up -d sprinkler_postgres

# View logs
docker compose logs -f sprinkler_postgres

# Stop without removing volumes (preserves database)
docker compose down

# DANGER: Remove volumes (deletes all database data)
docker compose down -v
```

### Database Management

**Connection Details:**
- Host: `sprinkler_postgres` (from containers) or `localhost` (from host)
- Port: 5432 (configurable via `POSTGRES_HOST_PORT`)
- Default DB: `sprinkler`
- Web App DB: `sprinkler_web` (auto-created by `postgresql/initdb/001-create-databases.sql`)
- Extensions: uuid-ossp, pgcrypto (pre-installed)

**Creating Backups:**
```powershell
# From Windows (container must be running)
docker compose exec sprinkler_postgres pg_dump -U sprinkler -Fc sprinkler_web -f /backups/sprinkler_web.dump
```

Files land in `postgresql/backups/` on the host.

### pgAdmin Access

**Local:** http://localhost:5050  
**Production:** https://pg.iotserver.uz (HTTPS only, HTTP redirects)

**First Connection to Database:**
1. Login to pgAdmin with credentials from `pgadmin/.env`
2. Server "Sprinkler PostgreSQL" is pre-configured (from `pgadmin/servers.json`)
3. Click server → enter PostgreSQL password from `postgresql/.env`

## Project-Specific Conventions

### Environment Variable Patterns

All services use `.env.example` templates that **must be copied to `.env`**:
- `postgresql/.env` - Database credentials, ports
- `pgadmin/.env` - Admin UI credentials, ports

**Never commit `.env` files** - they're in `.gitignore`. Default values in docker-compose.yml use `${VAR:-default}` syntax.

### Container Naming

All containers prefixed with `sprinkler_` to avoid conflicts on shared server:
- `sprinkler_postgres` - PostgreSQL 16
- `sprinkler_pgadmin` - pgAdmin web UI

### Network Architecture

Services communicate via `sprinkler_postgres_net` bridge network. When configuring:
- **From containers:** Use container names (e.g., `sprinkler_postgres:5432`)
- **From Nginx:** Use container names, NOT `localhost` (Nginx runs in separate container)
- **From host:** Use `localhost` with mapped ports

### Logging Standards

All services use JSON logging with rotation:
```yaml
logging:
  driver: json-file
  options:
    max-size: "50m"
    max-file: "3"
```

### Health Checks

Services define health checks for proper startup ordering:
- PostgreSQL: `pg_isready` every 10s
- pgAdmin: HTTP ping to `/misc/ping` every 10s

pgAdmin `depends_on` PostgreSQL health, not just startup.

## Integration Points

### Nginx Reverse Proxy (Production)

Reference config in `pgadmin/README.md` for HTTPS setup. **Critical:** Always use container names in `proxy_pass`, never `localhost`.

Example from production:
```nginx
location / {
    proxy_pass http://sprinkler_pgadmin:80;  # ✓ Container name
    # NOT http://localhost:5050              # ✗ Wrong in containerized Nginx
}
```

### GitHub Actions