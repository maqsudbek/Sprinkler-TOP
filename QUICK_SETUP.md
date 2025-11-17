# Sprinkler Infra Quick Steps

## 1. Post-clone prep
1. `cd /home/maqsud/sprinkler`
2. `cp postgresql/.env.example postgresql/.env`
3. `cp pgadmin/.env.example pgadmin/.env`
4. Edit both `.env` files with strong passwords/ports (do not commit them).

## 2. Bring services up
1. `docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d`
2. `docker compose ps`
3. `docker compose logs -f sprinkler_postgres` (CTRL+C when healthy)

## 3. Browser setup (Nginx already running)
1. Open your pgAdmin URL (e.g., `https://pg.iotserver.uz`).
2. Log in with `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD` from `pgadmin/.env`.
3. Click **Servers → Sprinkler PostgreSQL**.
4. Enter the PostgreSQL password from `postgresql/.env`.
5. Expand `Databases → sprinkler_web` to manage data.


---------------------------------------
## Some DB Details:
`postgres`: default maintenance DB that ships with PostgreSQL; used internally for admin tasks.  
`sprinkler`: core operational DB for system-wide data (shared by backend services).   
`sprinkler_web`: dedicated schema for the web applications/web UI layer (tables managed by Sprinkler web services).  

## Connection strings for backends

### Same-server apps (containerized)
When your backend runs **on the same server in a Docker container**, use the **container name** as host:

```python
# Example: FastAPI + SQLAlchemy
DATABASE_URL = "postgresql+asyncpg://sprinkler:YOUR_PASSWORD@sprinkler_postgres:5432/sprinkler"
```

**Key points:**
- Host: `sprinkler_postgres` (container name, NOT `localhost`)
- Port: `5432` (internal container port)
- Ensure your app container joins network: `sprinkler_postgres_net`

---

### Same-server apps (non-containerized)
If running **directly on the host** (not in Docker):

```python
DATABASE_URL = "postgresql+asyncpg://sprinkler:YOUR_PASSWORD@localhost:5432/sprinkler"
```

**Key points:**
- Host: `localhost` or `127.0.0.1`
- Port: Whatever you set in `POSTGRES_HOST_PORT` (default `5432`)

---

### Remote server backends
When your backend runs **on a different server**:

```python
DATABASE_URL = "postgresql+asyncpg://sprinkler:YOUR_PASSWORD@iotserver.uz:5432/sprinkler"
```

**Requirements:**
1. **Firewall:** Port `5432` must be open on the database server
2. **PostgreSQL config:** Edit `postgresql.conf` → set `listen_addresses = '*'`
3. **Authentication:** Edit `pg_hba.conf` → add remote IP with `md5` auth:
    ```
    host    all    all    <REMOTE_SERVER_IP>/32    md5
    ```
4. **Security:** Use strong passwords, consider SSH tunneling or VPN for production

---

### Local dev machine (internet access)
From your **Windows/Mac laptop** to the cloud database:

```python
DATABASE_URL = "postgresql+asyncpg://sprinkler:YOUR_PASSWORD@iotserver.uz:5432/sprinkler"
```

**Alternative (more secure):** SSH tunnel
```powershell
# Create tunnel (keeps port 5432 local-only)
ssh -L 5432:localhost:5432 maqsud@iotserver.uz

# Then connect to localhost
DATABASE_URL = "postgresql+asyncpg://sprinkler:YOUR_PASSWORD@localhost:5432/sprinkler"
```

**⚠️ Production warning:** Exposing PostgreSQL to the internet is risky. Always:
- Use SSH tunnels for dev access
- Whitelist only known IPs in firewall
- Rotate passwords regularly