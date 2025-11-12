# Sprinkler-TOP
Top Folder of Sprinkler IoT - main top folder structure (by Shoxrux)

## Project Structure

This repository contains the top-level structure for the Sprinkler IoT project. The project syncs with the server at `/home/maqsud/sprinkler`.

```
.
├── .github/              # GitHub configuration files
├── .gitignore            # Git ignore rules
├── docker-compose.yml    # Docker Compose configuration for the PostgreSQL service
├── postgresql/           # PostgreSQL database configuration, init scripts, and persistent storage mounts
├── README.md             # Project documentation (this file)
├── webapi/              # (Not tracked) Separate repository for Web API
└── webota/              # (Not tracked) Separate repository for Web OTA
```

**Note:** The `webapi/` and `webota/` folders are excluded from this repository as they are separate subprojects with their own repositories.

Here are those subproject repos:

- [webAPI](https://github.com/maqsudbek/Sprinkler-webAPI)
- [webOTA](https://github.com/maqsudbek/Sprinkler-webOTA)


## Final stack

- FastAPI + Uvicorn

- Auth: fastapi-users + passlib (bcrypt)

- DB/ORM: PostgreSQL + SQLAlchemy + asyncpg + Alembic

- Frontend: Jinja2 templates + Bootstrap

- Container: one Dockerfile per runnable service; Postgres in its own container with a named volume

- Dev tooling: pip + venv, requirements.txt and requirements-dev.txt; code quality via black + isort + ruff; tests with pytest; git hooks via pre-commit

### Authentication

Managed by fastapi-users inside webapi and webota.

WebAPI and WebOTA have common user/password and authentication system.

Passwords stored as bcrypt hashes via passlib.

Session handling can be secure cookies or JWT as configured in webapi and webota.

## PostgreSQL Runtime

- Local development: see `postgresql/README.md` for PowerShell-ready steps to start the container on Windows 11 using Docker Desktop inside VS Code.
- Cloud deployment: once this repo is mirrored to `/home/maqsud/sprinkler`, run the same root-level `docker compose` commands on the server to launch the database for remote access.
- Credentials: copy `postgresql/.env.example` to `postgresql/.env` (both locally and on the server) and set strong passwords before bringing the stack online.
- Compose usage: include `--env-file postgresql/.env` with `docker compose` commands so the same configuration is applied to both environments.

The same `postgresql` directory is used in both environments so the initialization SQL, backups, and configuration stay consistent.

The `_cloud-files/` folder is informational only; it captures the broader server configuration but is not modified by this project.


## Important Configs of Cloud Server

### Versions of Docker and Docker-Compose

command to check docker version:

```bash
docker --version
>> Docker version 20.10.24+dfsg1, build 297e128
```

command to check docker-compose version:

```bash
docker-compose --version
>> Docker Compose version v2.20.2
```


