# Sprinkler-TOP
Top Folder of Sprinkler IoT - main top folder structure (by Shoxrux)

## Project Structure

This repository contains the top-level structure for the Sprinkler IoT project. The project syncs with the server at `/home/maqsud/sprinkler`.

```
.
├── .github/              # GitHub configuration files
├── .gitignore            # Git ignore rules
├── postgresql/           # PostgreSQL database configuration
├── docker-compose.yml    # Docker Compose configuration
├── webapi/              # (Not tracked) Separate repository for Web API
└── webota/              # (Not tracked) Separate repository for Web OTA
```

**Note:** The `webapi/` and `webota/` folders are excluded from this repository as they are separate subprojects with their own repositories.

Here are those subproject repos:

- [webAPI](https://github.com/maqsudbek/Sprinkler-webAPI)
- [webOTA](https://github.com/maqsudbek/Sprinkler-webOTA)
