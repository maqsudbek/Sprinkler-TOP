# Sprinkler Stack Runbook (pg.iotserver.uz)

These operator notes explain exactly how to run and validate the Sprinkler PostgreSQL + pgAdmin stack on the production host (`/home/maqsud`). They tie together the project-level compose file, the global `docker-compose.yml`/`nginx/nginx.conf`, and the `pg.iotserver.uz` sub‑domain that already points to this server.

---

## 1. Scope and Directory Map

- `sprinkler/docker-compose.yml` – launches `sprinkler_postgres` and `sprinkler_pgadmin` and connects both to `mynetwork` so the top-level nginx container can reach pgAdmin.
- `sprinkler/postgresql/` – env file, init SQL (`001-create-databases.sql`), backups, and persistent data bind mounts.
- `sprinkler/pgadmin/` – env file, `servers.json`, nginx config snippets, troubleshooting notes.
- `nginx/nginx.conf` (outside this folder) – already contains the `pg.iotserver.uz` blocks that proxy to `sprinkler_pgadmin:80` using the wildcard certificate from `/etc/letsencrypt/live/iotserver.uz`.

All edits for this runbook stay inside `sprinkler/` as requested.

---

## 2. Prerequisites on the Host

- Docker Engine `20.10.24+dfsg1` and Docker Compose V2 `2.20.2` are already installed (see `docker --version`, `docker compose version`).
- Wildcard Let\'s Encrypt cert for `*.iotserver.uz` is present and renewed (`/etc/letsencrypt/live/iotserver.uz`).
- DNS for `pg.iotserver.uz` resolves to this host (confirmed with your provider).
- External Docker network `mynetwork` exists (created by the main compose stack). Verify before bringing Sprinkler online:

```bash
cd /home/maqsud
docker network ls | grep mynetwork
```

If it is missing (should not happen unless the main stack was torn down), recreate it once:

```bash
cd /home/maqsud
docker network create mynetwork
```

---

## 3. Environment Files and Secrets

Both services consume env files that already live under `sprinkler/` and are git-ignored.

```bash
cd /home/maqsud/sprinkler
ls postgresql/.env pgadmin/.env
```

Key expectations:

- `postgresql/.env` defines `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_HOST_PORT`, etc. These values seed both the `sprinkler` and `sprinkler_web` databases (see `postgresql/initdb/001-create-databases.sql`).
- `pgadmin/.env` holds `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD`, `PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=False`, and `PGADMIN_HOST_PORT=5050`.

If either env file is missing or needs rotation, copy from the matching `.env.example`, edit with a strong password, and keep the files on disk only (never commit or paste elsewhere).

---

## 4. Starting, Stopping, and Updating the Stack

Always operate from the Sprinkler folder so Compose picks up the correct file. On this host most Docker tooling (compose, logs, exec) runs under `sudo`, so the examples below include it where required.

```bash
cd /home/maqsud/sprinkler
```

### Start or Recreate Containers

```bash
sudo docker compose up -d
```

Env files are referenced via `env_file` in the compose file, so no `--env-file` flags are required.

### Stop Services (retain data)

```bash
sudo docker compose down
```

### Restart After Config Changes

```bash
sudo docker compose restart
```

### Pull Updated Images Before Restarting (when needed)

```bash
sudo docker compose pull
```

All persistent data stays in `postgresql/data` (bind mount) and `sprinkler_pgadmin_data` (named volume).

---

## 5. Health Checks and Validation

After `sudo docker compose up -d`, confirm both containers are running and healthy:

```bash
sudo docker compose ps
```

You should see `sprinkler_postgres` with `Up (healthy)` and `sprinkler_pgadmin` with either `Up (healthy)` or `Up` (pgAdmin still works even if the curl-based health check reports `unhealthy`).

Further verification steps:

```bash
# Confirm PostgreSQL accepts connections
sudo docker exec sprinkler_postgres pg_isready -U ${POSTGRES_USER}

# Drop into psql shell when needed
sudo docker exec -it sprinkler_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# Verify pgAdmin responds internally
sudo docker exec sprinkler_pgadmin curl -sf http://localhost/misc/ping
```

Remember that the root `docker-compose.yml` maps only nginx to the host HTTP/HTTPS ports (80/443). Every other application listens on nonstandard ports behind the reverse proxy to avoid conflicts, so never expose additional ports there unless you also coordinate with nginx.

---

## 6. Network Integration with nginx

The Sprinkler compose file attaches both services to `mynetwork` plus an internal bridge (`sprinkler_postgres_net`). To double-check DNS reachability from nginx:

```bash
sudo docker exec nginx ping -c3 sprinkler_pgadmin
sudo docker exec nginx curl -I http://sprinkler_pgadmin:80/login
```

If either command fails, ensure `sprinkler_pgadmin` is running and inspect network membership:

```bash
docker network inspect mynetwork | grep -E "sprinkler_pgadmin|nginx"
```

Add nginx to `mynetwork` (if it was recreated) by updating the top-level compose file and restarting that service.

---

## 7. Reverse Proxy Expectations (pg.iotserver.uz)

The active `nginx/nginx.conf` already contains the required server blocks. Review the bottom of the file to confirm the following characteristics:

- HTTPS block listens on `443` for `pg.iotserver.uz`, proxies to `http://sprinkler_pgadmin:80`, forwards standard headers, and sets long proxy timeouts.
- HTTP block listens on `80` and issues a `301` redirect to HTTPS.
- Certificate paths reference `/etc/letsencrypt/live/iotserver.uz/...` (wildcard cert).

After restarting Sprinkler, reload nginx only if you modified its config:

```bash
sudo docker exec nginx nginx -t
sudo docker exec nginx nginx -s reload
```

---

## 8. Domain-Level Smoke Tests

Once containers and nginx are up, perform the following from the host (or anywhere with network access):

```bash
# DNS resolution
nslookup pg.iotserver.uz

# HTTP should redirect to HTTPS
curl -I http://pg.iotserver.uz

# HTTPS should return 200 with the Let's Encrypt certificate
curl -I https://pg.iotserver.uz
```

Then open `https://pg.iotserver.uz` in a browser, sign in using the credentials stored in `pgadmin/.env`, and expand the pre-configured server entry “Sprinkler PostgreSQL” (loaded from `pgadmin/servers.json`). pgAdmin will prompt for the PostgreSQL password the first time; save it in pgAdmin’s master-password store if desired.

---

## 9. Routine Operations

| Task | Command |
| --- | --- |
| Tail PostgreSQL logs | `sudo docker logs -f sprinkler_postgres` |
| Tail pgAdmin logs | `sudo docker logs -f sprinkler_pgadmin` |
| Tail nginx logs (host-level compose) | `cd /home/maqsud && sudo docker compose logs --tail=50 -f nginx` |
| Execute SQL backup of `sprinkler_web` | `sudo docker exec sprinkler_postgres pg_dump -U ${POSTGRES_USER} -Fc sprinkler_web -f /backups/sprinkler_web_$(date +%Y%m%d).dump` |
| Copy most recent backup to another host | `rsync -avz postgresql/backups/ user@remote:/path/` |
| Remove orphaned pgAdmin volume (only if resetting) | `sudo docker volume rm sprinkler_pgadmin_data` |

Always verify backups land under `postgresql/backups/` on the host.

---

## 10. Troubleshooting pg.iotserver.uz

1. **Containers down** – `docker compose ps` should show both services. If not, restart with `docker compose up -d` and inspect logs.
2. **pgAdmin health check “unhealthy”** – The container still serves traffic; the curl binary sometimes exits non-zero. Confirm manually with `docker exec sprinkler_pgadmin curl -I http://localhost/login`.
3. **502/504 from nginx** – Usually means nginx cannot reach `sprinkler_pgadmin`. Run `docker exec nginx curl -I http://sprinkler_pgadmin:80/login`. If it fails, check that both containers share `mynetwork`.
4. **Redirect loop / too many redirects** – Ensure `PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=False` in both `pgadmin/.env` and `docker-compose.yml` (already set). Recreate pgAdmin if you change it.
5. **TLS mismatch** – Certificates live under `/etc/letsencrypt`. Renew all subdomains together using the wildcard cron or manually run `sudo certbot renew --dry-run` on the host. Because pgAdmin uses the wildcard cert, no additional certbot call is required unless you switch to a dedicated cert.
6. **DNS mismatch** – Run `dig +short pg.iotserver.uz`; if it does not point to this host, update the provider entry.

When investigating, capture logs first:

```bash
sudo docker logs --tail=200 sprinkler_pgadmin
sudo docker logs --tail=200 sprinkler_postgres
cd /home/maqsud && sudo docker compose logs --tail=200 nginx
```

---

## 11. Quick Command Reference

docker logs sprinkler_postgres
docker exec sprinkler_postgres pg_dump -U ${POSTGRES_USER} -Fc sprinkler_web -f /backups/sprinkler_web_$(date +%Y%m%d).dump
```bash
# Navigate to project
cd /home/maqsud/sprinkler

# Launch stack
sudo docker compose up -d

# Check status
sudo docker compose ps

# View logs
sudo docker logs sprinkler_postgres

# Backup database
sudo docker exec sprinkler_postgres pg_dump -U ${POSTGRES_USER} -Fc sprinkler_web -f /backups/sprinkler_web_$(date +%Y%m%d).dump

# Validate reverse proxy
nslookup pg.iotserver.uz
curl -I https://pg.iotserver.uz
```

Keep this file up to date with any future tweaks (new ports, passwords, or network names) so operations for the Sprinkler stack stay repeatable.
