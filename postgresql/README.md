# Sprinkler PostgreSQL Stack

This directory encapsulates the PostgreSQL runtime that powers the Sprinkler services. It is designed to work on a Windows 11 development machine, on the production cloud host, and for remote access over the internet.

## Contents

- Root-level `docker-compose.yml` – orchestrates the PostgreSQL container defined here.
- `.env.example` – template with the environment variables that drive the container setup. Copy it to `.env` and adapt values before running.
- `initdb/` – SQL scripts executed on first boot. They provision the database for the WebAPI service (`sprinkler_web`) and enable the extensions it relies on.
- `data/` (created automatically) – persistent database storage that remains across container restarts.
- `backups/` – optional host folder where logical backups can be stored.

## Running Locally (Windows 11)

1. Duplicate `.env.example` to `.env` and change the password:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Ensure Docker Desktop is running, then start the service from the repository root using the dedicated env file:
   ```powershell
   docker compose --env-file postgresql/.env up -d
   ```
3. Verify the container status:
   ```powershell
   docker compose ps
   ```

The database listens on `localhost:${POSTGRES_HOST_PORT}` (defaults to `5432`). The default user/database are `sprinkler` unless overridden in `.env`.

To stop the stack run `docker compose --env-file postgresql/.env down`. Append `-v` if you intentionally want to remove the persisted volume (this wipes the database files in `postgresql/data`).

## Backing Up Locally

Logical dumps can be taken from the container while it is running (the container must be started before running this command):
```powershell
docker compose --env-file postgresql/.env exec sprinkler_postgres pg_dump -U <db_user> -Fc sprinkler_web -f /backups/sprinkler_web.dump
```
Replace `<db_user>` with the `POSTGRES_USER` value defined in `postgresql/.env` (defaults to `sprinkler`). Use `sprinkler_web` to export the web database. The resulting dump files land in the `backups` directory.

## Cloud Deployment

After this repository is synced to `/home/maqsud/sprinkler` on the server:

1. Copy `postgresql/.env.example` to `postgresql/.env` and supply production credentials.
2. From `/home/maqsud/sprinkler` run:
   ```bash
   docker compose --env-file postgresql/.env up -d
   ```
3. Confirm the container is healthy with `docker compose ps`.

The database service listens on the port specified by `POSTGRES_HOST_PORT` (default `5432`). Expose or firewall that port according to your cloud security requirements.

Persisted data, init scripts, and backups live under `/home/maqsud/sprinkler/postgresql` on the server. This matches the Windows layout, so local and cloud environments stay in sync.
