# N8N Email Automation Deployment Guide

This comprehensive guide covers deploying the N8N Email Automation system in various environments, from local development to production-ready cloud deployments.

## Table of Contents

- [Deployment Overview](#deployment-overview)
- [Prerequisites](#prerequisites)
- [Local Development Deployment](#local-development-deployment)
- [Docker Deployment](#docker-deployment)
- [Cloud Deployment](#cloud-deployment)
- [Security Hardening](#security-hardening)
- [SSL/TLS Configuration](#ssltls-configuration)
- [Monitoring and Logging](#monitoring-and-logging)
- [Backup and Recovery](#backup-and-recovery)
- [Scaling and Performance](#scaling-and-performance)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

## Deployment Overview

### Architecture Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Google APIs   │    │     N8N App     │    │  Email Service  │
│                 │    │                 │    │                 │
│ • Sheets API    │◄──►│ • Workflows     │◄──►│ • Gmail API     │
│ • Gmail API     │    │ • Credentials   │    │ • SMTP          │
└─────────────────┘    │ • Executions    │    └─────────────────┘
                       └─────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │    Database     │
                    │                 │
                    │ • PostgreSQL    │
                    │ • Redis Cache   │
                    └─────────────────┘
```

### Deployment Options

| Option | Complexity | Scalability | Cost | Best For |
|--------|------------|-------------|------|----------|
| Local Development | Low | Low | Free | Testing, Development |
| Docker Compose | Medium | Medium | Low | Small to Medium Teams |
| Kubernetes | High | High | Medium | Enterprise, High Scale |
| Cloud Managed | Low | High | High | Quick Production Setup |

## Prerequisites

### System Requirements

**Minimum Requirements:**
- CPU: 2 cores
- RAM: 4GB
- Storage: 20GB SSD
- Network: Stable internet connection

**Recommended Production:**
- CPU: 4+ cores
- RAM: 8GB+
- Storage: 50GB+ SSD
- Network: High-speed internet with static IP

### Software Requirements

- **Docker & Docker Compose** (recommended)
- **Node.js 16+** (for manual installation)
- **PostgreSQL 12+** (database)
- **Redis 6+** (caching, optional but recommended)
- **Nginx/Traefik** (reverse proxy for production)

### Cloud Accounts & APIs

- **Google Cloud Platform** account with:
  - Google Sheets API enabled
  - Gmail API enabled
  - OAuth2 credentials configured
- **Domain name** (for production deployment)
- **SSL Certificate** (Let's Encrypt recommended)

## Local Development Deployment

### Method 1: Manual Installation

1. **Install Node.js and npm**
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS
brew install node

# Windows
# Download from nodejs.org
```

2. **Install n8n**
```bash
npm install -g n8n
```

3. **Set up environment**
```bash
cd n8n-email-automation
cp config/.env.example config/.env
# Edit config/.env with your settings
```

4. **Start n8n**
```bash
# Basic start
n8n start

# With custom config
N8N_CONFIG_FILES=./config/.env n8n start
```

5. **Access n8n**
- Open browser to `http://localhost:5678`
- Complete initial setup
- Import workflows from `workflows/email-automation-workflow.json`

### Method 2: Docker (Recommended for Development)

1. **Clone and configure**
```bash
git clone <repository-url>
cd n8n-email-automation
cp .env.docker .env
```

2. **Edit environment variables**
```bash
nano .env
# Update passwords, domains, and API credentials
```

3. **Start services**
```bash
# Start core services
docker-compose up -d postgres redis n8n

# View logs
docker-compose logs -f n8n
```

4. **Access and configure**
- Open `http://localhost:5678`
- Set up admin account
- Configure Google API credentials
- Import workflow

## Docker Deployment

### Production Docker Setup

1. **Prepare environment**
```bash
# Clone repository
git clone <repository-url>
cd n8n-email-automation

# Copy and configure environment
cp .env.docker .env
```

2. **Configure environment variables**
```bash
nano .env
```

Key variables to update:
```bash
# Security (CRITICAL)
POSTGRES_PASSWORD=your-secure-password
REDIS_PASSWORD=your-secure-redis-password
N8N_ENCRYPTION_KEY=your-32-character-encryption-key
JWT_SECRET=your-jwt-secret

# Domain and SSL
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://your-domain.com

# Database
POSTGRES_DB=n8n_production
POSTGRES_USER=n8n_user
```

3. **Deploy with profiles**
```bash
# Basic production deployment
COMPOSE_PROFILES=production docker-compose up -d

# With monitoring
COMPOSE_PROFILES=production,monitoring docker-compose up -d

# Full stack with backup
COMPOSE_PROFILES=production,monitoring,backup docker-compose up -d
```

4. **Verify deployment**
```bash
# Check service status
docker-compose ps

# Check logs
docker-compose logs -f n8n

# Test connectivity
curl -f http://localhost:5678/healthz
```

### Docker Compose Profiles

Enable different service combinations:

```bash
# Production with Nginx reverse proxy
COMPOSE_PROFILES=production docker-compose up -d

# Production with Traefik and SSL
COMPOSE_PROFILES=traefik docker-compose up -d

# Add monitoring stack
COMPOSE_PROFILES=production,monitoring docker-compose up -d

# Full stack with logging and backup
COMPOSE_PROFILES=production,monitoring,logging,backup docker-compose up -d
```

## Cloud Deployment

### AWS Deployment

#### Option 1: EC2 with Docker

1. **Launch EC2 instance**
```bash
# Create EC2 instance (t3.medium or larger recommended)
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.medium \
  --key-name your-key-pair \
  --security-groups n8n-security-group \
  --user-data file://user-data.sh
```

2. **Security group configuration**
```bash
# Create security group
aws ec2 create-security-group \
  --group-name n8n-security-group \
  --description "N8N Email Automation"

# Allow HTTP/HTTPS and SSH
aws ec2 authorize-security-group-ingress \
  --group-name n8n-security-group \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name n8n-security-group \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-name n8n-security-group \
  --protocol tcp \
  --port 22 \
  --cidr your.ip.address/32
```

3. **User data script** (user-data.sh):
```bash
#!/bin/bash
yum update -y
yum install -y docker git

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
service docker start
usermod -a -G docker ec2-user

# Clone and setup
cd /opt
git clone <repository-url> n8n-email-automation
cd n8n-email-automation
cp .env.docker .env

# Start services
docker-compose up -d
```

#### Option 2: ECS Fargate

1. **Create ECS cluster**
```bash
aws ecs create-cluster --cluster-name n8n-cluster
```

2. **Create task definition**
```json
{
  "family": "n8n-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "n8n",
      "image": "n8nio/n8n:latest",
      "portMappings": [
        {
          "containerPort": 5678,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DB_TYPE",
          "value": "postgresdb"
        },
        {
          "name": "DB_POSTGRESDB_HOST",
          "value": "your-rds-endpoint"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/n8n",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

3. **Create service**
```bash
aws ecs create-service \
  --cluster n8n-cluster \
  --service-name n8n-service \
  --task-definition n8n-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345],securityGroups=[sg-12345],assignPublicIp=ENABLED}"
```

### Google Cloud Platform

1. **Create GKE cluster**
```bash
gcloud container clusters create n8n-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10
```

2. **Deploy using Kubernetes manifests**
```yaml
# kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: n8n-automation

---
# kubernetes/postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: n8n-automation
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: n8n
        - name: POSTGRES_USER
          value: n8n
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
# kubernetes/n8n-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: n8n-automation
spec:
  replicas: 2
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
      - name: n8n
        image: n8nio/n8n:latest
        env:
        - name: DB_TYPE
          value: postgresdb
        - name: DB_POSTGRESDB_HOST
          value: postgres-service
        - name: N8N_PORT
          value: "5678"
        ports:
        - containerPort: 5678
        livenessProbe:
          httpGet:
            path: /healthz
            port: 5678
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 5
```

3. **Deploy to cluster**
```bash
kubectl apply -f kubernetes/
```

### DigitalOcean Deployment

1. **Create Droplet**
```bash
# Using doctl
doctl compute droplet create n8n-automation \
  --image docker-20-04 \
  --size s-2vcpu-4gb \
  --region nyc1 \
  --ssh-keys your-ssh-key-fingerprint \
  --user-data-file user-data.sh
```

2. **Configure floating IP**
```bash
doctl compute floating-ip create --region nyc1
doctl compute floating-ip-action assign <floating-ip> <droplet-id>
```

## Security Hardening

### Basic Security Measures

1. **Change default passwords**
```bash
# Generate strong passwords
openssl rand -base64 32  # For database passwords
openssl rand -hex 16     # For API keys
```

2. **Configure firewall**
```bash
# Ubuntu UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL firewalld
sudo firewall-cmd --permanent --zone=public --add-service=ssh
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
```

3. **Secure file permissions**
```bash
# Set proper permissions on config files
chmod 600 config/.env
chmod 600 .env
chown root:root config/.env .env

# Secure Docker socket (if needed)
chmod 660 /var/run/docker.sock
```

4. **Network security**
```bash
# Disable unnecessary services
sudo systemctl disable telnet
sudo systemctl disable ftp

# Configure SSH security
sudo nano /etc/ssh/sshd_config
# Add these lines:
# PermitRootLogin no
# PasswordAuthentication no
# AllowUsers your-username
```

### Advanced Security

1. **Container security**
```yaml
# docker-compose security enhancements
services:
  n8n:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    user: "1000:1000"
```

2. **Network segmentation**
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

3. **Secrets management**
```bash
# Using Docker secrets
echo "secure_password" | docker secret create postgres_password -
```

### Security Checklist

- [ ] All default passwords changed
- [ ] Firewall configured and active
- [ ] SSL/TLS certificates installed
- [ ] Regular security updates enabled
- [ ] Log monitoring configured
- [ ] Backup encryption enabled
- [ ] API rate limiting configured
- [ ] Container security hardening applied
- [ ] Network segmentation implemented
- [ ] Secrets management in place

## SSL/TLS Configuration

### Let's Encrypt with Certbot

1. **Install Certbot**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx
```

2. **Obtain certificate**
```bash
sudo certbot --nginx -d your-domain.com
```

3. **Auto-renewal setup**
```bash
sudo crontab -e
# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet
```

### Traefik with Let's Encrypt

```yaml
# traefik.yml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      tlsChallenge: {}
      email: your-email@domain.com
      storage: acme.json

http:
  routers:
    n8n:
      rule: "Host(`your-domain.com`)"
      tls:
        certResolver: letsencrypt
      service: n8n

  services:
    n8n:
      loadBalancer:
        servers:
          - url: "http://n8n:5678"
```

### Manual SSL Configuration

1. **Generate certificate**
```bash
# Self-signed (development only)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Or purchase from CA
```

2. **Nginx SSL configuration**
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Monitoring and Logging

### Prometheus Monitoring

1. **Configure Prometheus**
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'n8n'
    static_configs:
      - targets: ['n8n:5678']
    metrics_path: /metrics
    scrape_interval: 30s
```

2. **Grafana dashboard setup**
```bash
# Import n8n dashboard
curl -X POST \
  http://admin:password@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @monitoring/grafana/n8n-dashboard.json
```

### Log Management

1. **Centralized logging with Loki**
```yaml
# monitoring/loki-config.yml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
```

2. **Application logging**
```javascript
// Enhanced logging in n8n workflows
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Usage in Code nodes
logger.info('Email campaign started', {
  campaign_id: $json.campaign_id,
  recipient_count: $json.recipient_count,
  timestamp: new Date().toISOString()
});
```

### Health Checks

1. **Application health check**
```bash
#!/bin/bash
# health-check.sh

N8N_URL="http://localhost:5678"
HEALTH_ENDPOINT="$N8N_URL/healthz"

# Check n8n health
if curl -f -s "$HEALTH_ENDPOINT" > /dev/null; then
    echo "N8N is healthy"
    exit 0
else
    echo "N8N health check failed"
    exit 1
fi
```

2. **Database health check**
```bash
#!/bin/bash
# db-health-check.sh

POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_DB="n8n"
POSTGRES_USER="n8n"

if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q' 2>/dev/null; then
    echo "Database is healthy"
    exit 0
else
    echo "Database health check failed"
    exit 1
fi
```

### Alerting

1. **Alertmanager configuration**
```yaml
# monitoring/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@yourdomain.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@yourdomain.com'
        subject: 'N8N Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}

    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: 'N8N Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

2. **Alert rules**
```yaml
# monitoring/alert-rules.yml
groups:
  - name: n8n-alerts
    rules:
      - alert: N8NDown
        expr: up{job="n8n"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "N8N instance is down"
          description: "N8N has been down for more than 1 minute"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 90% for more than 2 minutes"

      - alert: DiskSpaceLow
        expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk space is running low"
          description: "Less than 20% disk space remaining"
```

## Backup and Recovery

### Automated Backup Strategy

1. **Database backup script**
```bash
#!/bin/bash
# scripts/backup.sh

# Configuration
BACKUP_DIR="/backups"
POSTGRES_HOST="postgres"
POSTGRES_DB="n8n"
POSTGRES_USER="n8n"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Database backup
echo "Starting database backup..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --verbose \
  --clean \
  --no-owner \
  --no-privileges \
  --format=custom \
  --file="$BACKUP_DIR/n8n_backup_$DATE.sql"

# Compress backup
gzip "$BACKUP_DIR/n8n_backup_$DATE.sql"

# Backup n8n data directory
echo "Backing up n8n data..."
tar -czf "$BACKUP_DIR/n8n_data_$DATE.tar.gz" \
  -C /home/node/.n8n \
  --exclude='*.log' \
  --exclude='cache/*' \
  .

# Clean old backups
find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "n8n_data_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: n8n_backup_$DATE.sql.gz"
```

2. **Restore script**
```bash
#!/bin/bash
# scripts/restore.sh

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    exit 1
fi

BACKUP_FILE=$1
POSTGRES_HOST="postgres"
POSTGRES_DB="n8n"
POSTGRES_USER="n8n"

# Extract backup
echo "Extracting backup..."
gunzip -c "$BACKUP_FILE" > "/tmp/restore.sql"

# Restore database
echo "Restoring database..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_restore \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --verbose \
  --clean \
  --if-exists \
  "/tmp/restore.sql"

# Clean up
rm "/tmp/restore.sql"

echo "Restore completed"
```

### Cloud Backup Integration

1. **AWS S3 backup**
```bash
#!/bin/bash
# scripts/backup-s3.sh

S3_BUCKET="your-n8n-backups"
AWS_REGION="us-east-1"
LOCAL_BACKUP_DIR="/backups"

# Run local backup first
./backup.sh

# Upload to S3
latest_backup=$(ls -t $LOCAL_BACKUP_DIR/n8n_backup_*.sql.gz | head -1)
latest_data=$(ls -t $LOCAL_BACKUP_DIR/n8n_data_*.tar.gz | head -1)

aws s3 cp "$latest_backup" "s3://$S3_BUCKET/database/" --region "$AWS_REGION"
aws s3 cp "$latest_data" "s3://$S3_BUCKET/data/" --region "$AWS_REGION"

echo "Backups uploaded to S3"
```

2. **Google Cloud Storage backup**
```bash
#!/bin/bash
# scripts/backup-gcs.sh

GCS_BUCKET="your-n8n-backups"
LOCAL_BACKUP_DIR="/backups"

# Run local backup first
./backup.sh

# Upload to GCS
latest_backup=$(ls -t $LOCAL_BACKUP_DIR/n8n_backup_*.sql.gz | head -1)
latest_data=$(ls -t $LOCAL_BACKUP_DIR/n8n_data_*.tar.gz | head -1)

gsutil cp "$latest_backup" "gs://$GCS_BUCKET/database/"
gsutil cp "$latest_data" "gs://$GCS_BUCKET/data/"

echo "Backups uploaded to Google Cloud Storage"
```

### Disaster Recovery Plan

1. **Recovery checklist**
   - [ ] Identify extent of data loss
   - [ ] Locate latest valid backup
   - [ ] Prepare clean environment
   - [ ] Restore database
   - [ ] Restore n8n configuration
   - [ ] Verify workflows and credentials
   - [ ] Test email functionality
   - [ ] Update DNS if necessary
   - [ ] Notify stakeholders

2. **Emergency contacts and procedures**
```bash
# Create emergency runbook
cat > emergency-runbook.md << EOF
# N8N Emergency Recovery Runbook

## Contacts
- Primary Admin: admin@company.com, +1-555-0123
- Secondary Admin: backup@company.com, +1-555-0124
- Infrastructure Team: infra@company.com

## Critical Information
- Database Host: [HOST]
- Backup Location: [S3/GCS BUCKET]
- Domain Registrar: [REGISTRAR]
- SSL Certificate Provider: [PROVIDER]

## Quick Recovery Steps
1. Launch new server from AMI/Image
2. Run restoration script: ./scripts/restore.sh
3. Update DNS A records to new IP
4. Verify SSL certificate renewal
5. Test critical workflows
EOF
```

## Scaling and Performance

### Horizontal Scaling

1. **Load balancer configuration**
```nginx
# nginx load balancer
upstream n8n_backend {
    server n8n-1:5678;
    server n8n-2:5678;
    server n8n-3:5678;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://n8n_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

2. **Database scaling**
```yaml
# PostgreSQL with read replicas
version: '3.8'
services:
  postgres-primary:
    image: postgres:15-alpine
    environment:
      - POSTGRES_REPLICATION_MODE=master
      - POSTGRES_REPLICATION_USER=replicator
      - POSTGRES_REPLICATION_PASSWORD=repl_password
    
  postgres-replica:
    image: postgres:15-alpine
    depends_on:
      - postgres-primary
    environment:
      - POSTGRES_REPLICATION_MODE=slave
      - POSTGRES_REPLICATION_USER=replicator
      - POSTGRES_REPLICATION_PASSWORD=repl_password
      - POSTGRES_MASTER_HOST=postgres-primary
```

### Performance Optimization

1. **Database optimization**
```sql
-- PostgreSQL performance tuning
-- /var/lib/postgresql/data/postgresql.conf

shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics