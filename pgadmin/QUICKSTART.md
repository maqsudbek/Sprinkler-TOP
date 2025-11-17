# Quick Start Guide - Testing pgAdmin Setup

This guide will help you test the pgAdmin setup on both local Windows 11 and cloud deployment.

---

## Local Development (Windows 11)

### Prerequisites

- Docker Desktop installed and running
- Both `postgresql/.env` and `pgadmin/.env` configured

## Step 1: Verify Environment Files

Check that both environment files exist and have proper passwords set:

```powershell
# Check PostgreSQL environment
Get-Content postgresql\.env

# Check pgAdmin environment
Get-Content pgadmin\.env
```

## Step 2: Start Services

Start both PostgreSQL and pgAdmin containers:

```powershell
docker compose --env-file postgresql\.env --env-file pgadmin\.env up -d
```

Expected output:
```
[+] Running 2/2
 ✔ Container sprinkler_postgres  Started
 ✔ Container sprinkler_pgadmin   Started
```

## Step 3: Verify Containers

Check that both containers are running and healthy:

```powershell
docker compose ps
```

Expected output:
```
NAME                 IMAGE                     STATUS
sprinkler_pgadmin    dpage/pgadmin4:latest     Up X seconds (healthy)
sprinkler_postgres   postgres:16               Up X seconds (healthy)
```

## Step 4: Access pgAdmin

1. Open your browser and navigate to: http://localhost:5050

2. Login with credentials from `pgadmin/.env`:
   - Email: `admin@iotserver.uz` (or your custom email)
   - Password: (value from `PGADMIN_DEFAULT_PASSWORD`)

3. You should see the pgAdmin dashboard

## Step 5: Connect to PostgreSQL

1. In pgAdmin's left sidebar, expand **Servers**

2. Click on **Sprinkler PostgreSQL**

3. When prompted for password, enter the PostgreSQL password from `postgresql/.env`:
   - Password: (value from `POSTGRES_PASSWORD`)
   - Optional: Check "Save password" for convenience

4. Once connected, you should see:
   - Databases
     - postgres (default)
     - sprinkler
     - sprinkler_web
     - template0
     - template1

## Step 6: Run Test Queries

1. Right-click on **sprinkler_web** database → **Query Tool**

2. Run this test SQL:

```sql
-- Create a test table
CREATE TABLE IF NOT EXISTS test_pgadmin (
    id SERIAL PRIMARY KEY,
    message VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO test_pgadmin (message) 
VALUES ('pgAdmin web interface is working!');

-- Query the data
SELECT * FROM test_pgadmin;

-- Clean up
DROP TABLE test_pgadmin;
```

3. Click the **Execute** button (▶ icon) or press `F5`

4. You should see the results in the **Data Output** panel

## Step 7: Test from Desktop App

To verify database consistency, test the same query in DBeaver:

1. Open DBeaver
2. Connect to `localhost:5432/sprinkler_web`
3. Run the same SQL queries
4. Results should match what you see in pgAdmin

## Troubleshooting

### pgAdmin doesn't start

```powershell
# Check logs
docker compose logs sprinkler_pgadmin

# Common fix: restart the container
docker compose restart sprinkler_pgadmin
```

### Cannot connect to PostgreSQL from pgAdmin

**Issue**: "Unable to connect to server"

**Solution**: Ensure you're using the correct hostname:
- ✅ Use: `sprinkler_postgres` (container name)
- ❌ Don't use: `localhost` or `127.0.0.1`

The `servers.json` file already has this configured correctly.

### Port 5050 already in use

```powershell
# Check what's using port 5050
netstat -ano | findstr :5050

# Option 1: Stop the conflicting process
# Option 2: Change PGADMIN_HOST_PORT in pgadmin/.env to another port (e.g., 5051)
```

### Forgot pgAdmin password

1. Stop the container:
   ```powershell
   docker compose stop sprinkler_pgadmin
   ```

2. Change password in `pgadmin/.env`

3. Remove the volume to reset:
   ```powershell
   docker volume rm sprinkler_pgadmin_data
   ```

4. Restart:
   ```powershell
   docker compose --env-file postgresql\.env --env-file pgadmin\.env up -d
   ```

## Next Steps

Once local testing is complete:

1. **Commit changes** to repository
2. **Push to GitHub**
3. **Pull on cloud server**: `cd /home/maqsud/sprinkler && git pull`
4. **Copy environment files** on server
5. **Start services** on server
6. **Configure Nginx** for `pg.iotserver.uz` (see `pgadmin/README.md`)
7. **Setup SSL certificate** with Let's Encrypt
8. **Access via HTTPS**: https://pg.iotserver.uz

## Clean Up (Optional)

To stop and remove everything:

```powershell
# Stop containers
docker compose down

# Remove volumes (WARNING: deletes all data)
docker volume rm sprinkler_pgadmin_data

# Remove images
docker rmi dpage/pgadmin4:latest postgres:16
```

## Success Criteria

✅ Both containers running and healthy  
✅ pgAdmin accessible at http://localhost:5050  
✅ Can login to pgAdmin  
✅ Can connect to PostgreSQL from pgAdmin  
✅ Can execute SQL queries  
✅ Test queries return expected results  
✅ Changes persist after container restart  

If all criteria are met, your pgAdmin setup is working correctly!

---

## Cloud Deployment (Linux Server)

### Prerequisites

- Server with Docker and Docker Compose installed
- Repository cloned to `/home/maqsud/sprinkler`
- Both environment files configured on server
- DNS configured for `pg.iotserver.uz`
- Nginx configured (see `NGINX_SETUP.md`)

### Step 1: Prepare Server

```bash
# SSH into your server
ssh user@your-server-ip

# Navigate to project directory
cd /home/maqsud/sprinkler

# Pull latest changes
git pull origin dev
```

### Step 2: Configure Environment Files

```bash
# Copy PostgreSQL environment file
cp postgresql/.env.example postgresql/.env
nano postgresql/.env
# Set strong POSTGRES_PASSWORD

# Copy pgAdmin environment file
cp pgadmin/.env.example pgadmin/.env
nano pgadmin/.env
# Set strong PGADMIN_DEFAULT_PASSWORD
# Update PGADMIN_DEFAULT_EMAIL if needed
```

### Step 3: Start Services

```bash
# Start both PostgreSQL and pgAdmin
docker compose --env-file postgresql/.env --env-file pgadmin/.env up -d

# Verify containers are running
docker compose ps
```

Expected output:
```
NAME                 IMAGE                     STATUS
sprinkler_pgadmin    dpage/pgadmin4:latest     Up (healthy)
sprinkler_postgres   postgres:16               Up (healthy)
```

### Step 4: Configure Nginx

Follow the detailed steps in `NGINX_SETUP.md`:

```bash
# Backup existing nginx config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Edit nginx config
sudo nano /etc/nginx/nginx.conf
# Add pgAdmin server blocks from NGINX_SETUP.md

# Test nginx configuration
sudo nginx -t

# Obtain SSL certificate
sudo certbot --nginx -d pg.iotserver.uz

# Reload nginx
sudo systemctl reload nginx
```

### Step 5: Verify DNS Resolution

```bash
# Check DNS is working
nslookup pg.iotserver.uz
# Should return your server IP

# Test HTTPS access
curl -I https://pg.iotserver.uz
# Should return HTTP/2 200
```

### Step 6: Access pgAdmin Web Interface

1. Open browser and navigate to: https://pg.iotserver.uz

2. Login with credentials from server's `pgadmin/.env`:
   - Email: (value from `PGADMIN_DEFAULT_EMAIL`)
   - Password: (value from `PGADMIN_DEFAULT_PASSWORD`)

3. You should see the pgAdmin dashboard

### Step 7: Connect to PostgreSQL

1. In pgAdmin's left sidebar, expand **Servers**

2. Click on **Sprinkler PostgreSQL**

3. When prompted for password, enter the PostgreSQL password from `postgresql/.env`:
   - Password: (value from `POSTGRES_PASSWORD`)
   - Optional: Check "Save password" for convenience

4. Once connected, you should see all databases including `sprinkler_web`

### Step 8: Run Test Queries

1. Right-click on **sprinkler_web** database → **Query Tool**

2. Run this test SQL:

```sql
-- Create a test table
CREATE TABLE IF NOT EXISTS test_cloud_deployment (
    id SERIAL PRIMARY KEY,
    message VARCHAR(200),
    deployment_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO test_cloud_deployment (message, deployment_type) 
VALUES ('pgAdmin cloud deployment successful!', 'production');

-- Query the data
SELECT * FROM test_cloud_deployment;

-- Clean up
DROP TABLE test_cloud_deployment;
```

3. Execute and verify results

### Step 9: Check Logs

```bash
# Check pgAdmin container logs
docker compose logs -f sprinkler_pgadmin

# Check nginx access logs
sudo tail -f /var/log/nginx/pgadmin_access.log

# Check nginx error logs
sudo tail -f /var/log/nginx/pgadmin_error.log
```

### Cloud Troubleshooting

#### Cannot access https://pg.iotserver.uz

**Check DNS:**
```bash
nslookup pg.iotserver.uz
dig pg.iotserver.uz
```

**Check Nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

**Check SSL Certificate:**
```bash
sudo certbot certificates
```

#### 502 Bad Gateway

**Check pgAdmin container:**
```bash
docker compose ps sprinkler_pgadmin
docker compose logs sprinkler_pgadmin
```

**Restart if needed:**
```bash
docker compose restart sprinkler_pgadmin
```

#### Cannot connect to PostgreSQL from pgAdmin

**Verify network:**
```bash
docker network inspect sprinkler_postgres_net
# Both containers should be listed
```

**Check PostgreSQL container:**
```bash
docker compose ps sprinkler_postgres
docker compose logs sprinkler_postgres
```

### Cloud Security Checklist

- [ ] Strong passwords in both `.env` files
- [ ] HTTPS/SSL certificate configured
- [ ] HTTP redirects to HTTPS
- [ ] Security headers enabled in Nginx
- [ ] Firewall rules configured (ports 80, 443)
- [ ] Optional: IP whitelisting configured
- [ ] Optional: HTTP basic auth enabled
- [ ] Regular backups configured
- [ ] SSL certificate auto-renewal tested

### Cloud Success Criteria

✅ DNS resolves `pg.iotserver.uz` to server IP  
✅ Both containers running and healthy  
✅ Nginx configured and running  
✅ SSL certificate valid  
✅ HTTPS accessible (HTTP redirects)  
✅ Can login to pgAdmin  
✅ Can connect to PostgreSQL from pgAdmin  
✅ Can execute SQL queries  
✅ Changes persist after container restart  
✅ Access logs recording requests  

If all criteria are met, your cloud deployment is successful! 🎉
