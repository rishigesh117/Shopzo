# SHOPZO — PostgreSQL Cloud Database Backup & Recovery Operational Guide

## Overview
This document provides production procedures for running automated backups, point-in-time recovery, and disaster recovery operations for the SHOPZO PostgreSQL cloud database.

---

## 1. Automated Automated Daily Backups (`pg_dump`)

### Cron Job Setup (Linux Server / Docker Container)
To perform nightly automated database exports at 02:00 AM:

```bash
# Edit crontab
crontab -e

# Add the following line:
0 2 * * * pg_dump -U shopzo_user -h shopzo-db.internal -d shopzo_db -F c -b -v -f "/var/backups/shopzo/shopzo_db_$(date +\%Y\%m\%d_\%H\%M\%S).dump"
```

### Environment File Configuration (`.env`)
```env
PGHOST=shopzo-db.internal
PGPORT=5432
PGDATABASE=shopzo_db
PGUSER=shopzo_user
PGPASSWORD=your_secure_password
```

---

## 2. Manual Backup Execution

To execute an immediate snapshot backup:

```bash
pg_dump -U shopzo_user -d shopzo_db -F c -b -v -f "./shopzo_db_manual_backup.dump"
```

---

## 3. Disaster Recovery & Restore Process

### Step 1: Terminate Active Backend Connections
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'shopzo_db' AND pid <> pg_backend_pid();
```

### Step 2: Drop and Recreate Target Database
```sql
DROP DATABASE IF EXISTS shopzo_db;
CREATE DATABASE shopzo_db OWNER shopzo_user;
```

### Step 3: Execute Database Restore
```bash
pg_restore -U shopzo_user -d shopzo_db -v "./shopzo_db_manual_backup.dump"
```

---

## 4. Retention & Storage Policy
1. **Daily Backups**: Retained for 30 days.
2. **Weekly Snapshots**: Retained for 12 months in cloud object storage (e.g., AWS S3 / Google Cloud Storage with versioning & AES-256 encryption enabled).
3. **Recovery Time Objective (RTO)**: < 15 minutes.
4. **Recovery Point Objective (RPO)**: Daily or real-time WAL streaming.
