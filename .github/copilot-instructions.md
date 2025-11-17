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

### GitHub Actions Deployment

On push to `main`, `.github/workflows/deploy.yml`:
1. SSHs to server (`/home/maqsud/sprinkler`)
2. Pulls latest from GitHub
3. **Does NOT restart services** - manual restart required if compose file changed

Repository uses SSH alias `github-sprinkler` on server for git operations.

### webapi/webota Integration

These folders exist on server but are **excluded from this repo** (see `.gitignore`). They:
- Share the same `sprinkler_postgres` database
- Connect to `sprinkler_web` database via SQLAlchemy
- Use same network: `sprinkler_postgres_net`
- Have separate docker-compose files in their respective repos

## File Structure Significance

```
.
├── docker-compose.yml          # Main service orchestration
├── postgresql/
│   ├── initdb/                 # SQL runs on first boot only
│   │   └── 001-create-databases.sql
│   ├── data/                   # Persistent storage (gitignored)
│   └── backups/                # Manual backups location
├── pgadmin/
│   ├── servers.json            # Pre-configured DB connections
│   └── .env.example            # Login credentials template
└── _cloud-files/               # Reference only - NOT deployed
    ├── nginx.conf              # Existing server Nginx config
    └── README.md               # Context about server environment
```

**Deployment paths:**
- Local dev: Project root (any directory)
- Server: `/home/maqsud/sprinkler` (hardcoded in GitHub Actions)

## Common Pitfalls

1. **Forgetting env files:** Always use `--env-file` flag or compose fails with missing vars
2. **Using localhost in containers:** Container-to-container communication requires container names
3. **Editing running config:** Changes to docker-compose.yml require `docker compose up -d` to apply
4. **Backup before volume removal:** `docker compose down -v` is destructive - backup first
5. **HTTP access in production:** pgAdmin only allows HTTPS, HTTP redirects (security requirement)

## Tech Stack

- **Database:** PostgreSQL 16 with uuid-ossp and pgcrypto extensions
- **Admin UI:** pgAdmin 4 (latest)
- **Container Runtime:** Docker 20.10.24, Docker Compose v2.20.2
- **OS:** Ubuntu (server), Windows 11 (dev)
- **Web Apps:** FastAPI + SQLAlchemy + asyncpg (in separate repos)

## Quick Reference Commands

```bash
# Check service health
docker compose ps

# Follow logs for debugging
docker compose logs -f sprinkler_postgres

# Restart after config change
docker compose up -d

# Connect to PostgreSQL CLI
docker compose exec sprinkler_postgres psql -U sprinkler -d sprinkler_web

# Inspect network
docker network inspect sprinkler_postgres_net
```
