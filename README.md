# Wave Forecast OSS Lakehouse
A complete, open-source data lakehouse solution for wave forecasting, built with modern data engineering tools.

## Architecture Overview
This lakehouse implementation combines best-in-class open-source tools:
- **MinIO**: S3-compatible object storage with medallion architecture (bronze/silver/gold)
- **Dremio**: SQL query engine for data lakehouse
- **Airbyte**: Data integration platform with 300+ source connectors
- **dbt**: For data transformation between silver and gold layers
- **Airflow**: Workflow orchestration and scheduling
- **Superset**: Business intelligence and data visualization platform
- **Briefer**: Collaborative data notebooks and dashboards

![architecture](/docs/architecture.png)

## Repository Structure
```bash
wave-forecast-oss-lakehouse/
├── airflow/                    # Airflow orchestration service
│   ├── docker-compose.yml      # Airflow service definition
│   ├── .env                    # Airflow environment variables
│   ├── dags/                   # Airflow DAG definitions
│   ├── logs/                   # Airflow execution logs
│   ├── plugins/                # Custom Airflow plugins
│   ├── config/                 # Airflow configuration
│   └── Dockerfile              # Custom Airflow image
├── minio/                      # MinIO object storage service
│   ├── docker-compose.yml      # MinIO service definition
│   └── .env                    # MinIO credentials
├── dremio/                     # Dremio query engine service
│   ├── docker-compose.yml      # Dremio service definition
│   ├── .env                    # Dremio configuration
│   └── config/                 # Dremio configuration files
├── airbyte/                    # Airbyte data integration service
│   └── README.md               # Guide to configure Airbyte
├── superset/                   # Superset BI & visualization service
│   ├── docker-compose.yml      # Superset service definition
│   ├── .env                    # Superset configuration
│   └── config/                 # Superset configuration files
├── briefer/                    # Briefer notebooks & dashboards service
│   ├── docker-compose.yml      # Briefer service definition
│   └── .env                    # Briefer configuration
├── docker-compose.yml          # Main orchestration file
└── README.md                   # This file
```

## Quick Start
### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- Minimum 8GB RAM available for Docker
- 20GB free disk space

### Starting All Services
```bash
# Start all services
docker-compose --profile all up -d

# Check service status
docker-compose ps
```

### Starting Individual Services
You can start services individually or in groups:
```bash
# Start only MinIO
docker-compose --profile minio up -d

# Start MinIO and Dremio
docker-compose --profile minio --profile dremio up -d

# Start Airbyte only
abctl local install

# Start Airflow only
docker-compose --profile airflow up -d

# Start Superset only
docker-compose --profile superset up -d

# Start Briefer only
docker-compose --profile briefer up -d
```

### Alternative: Start Services from Their Own Directories
Each service can be started independently from its directory:
```bash
# Create the shared network first
docker network create lakehouse-network

# Start MinIO
cd minio && docker-compose up -d && cd ..

# Start Dremio
cd dremio && docker-compose up -d && cd ..

# Start Airbyte
abctl local install

# Start Airflow
cd airflow && docker-compose up -d && cd ..

# Start Superset
cd superset && docker-compose up -d && cd ..

# Start Briefer
cd briefer && docker-compose up -d && cd ..
```

## Service Access Points
Once all services are running, access them at:
| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Airflow** | http://localhost:8080 | `waves-for-me` / `waves-for-me` |
| **MinIO Console** | http://localhost:9001 | `waves-for-me` / `waves-for-me` |
| **MinIO API** | http://localhost:9000 | - |
| **Dremio** | http://localhost:9047 | Set on first login |
| **Airbyte** | http://localhost:8000 | Set on `abctl local credentials` |
| **Airbyte API** | http://localhost:8001 | - |
| **Superset** | http://localhost:8088 | `waves-for-me` / `waves-for-me` |
| **Briefer** | http://localhost:3000 | Sign up on first access |

## MinIO Buckets (Medallion Architecture)
The MinIO storage is organized into four buckets:
- **bronze**: Raw and ingested data
- **silver**: Cleaned and enriched data
- **gold**: Business-ready aggregated data

## Configuration
### Environment Variables
Each service has its own `.env` file in its directory. Key configurations:
**Airflow** (`airflow/.env`):
- `POSTGRES_USER`, `POSTGRES_PASSWORD`: Airflow metadata DB credentials
- `_AIRFLOW_WWW_USER_USERNAME`, `_AIRFLOW_WWW_USER_PASSWORD`: Airflow web UI login
- `AIRFLOW__CORE__FERNET_KEY`: Encryption key for sensitive data
- `SLACK_WEBHOOK_URL`: Slack notifications

**MinIO** (`minio/.env`):
- `MINIO_ROOT_USER`: MinIO admin username
- `MINIO_ROOT_PASSWORD`: MinIO admin password

**Dremio** (`dremio/.env`):
- `DREMIO_MAX_MEMORY_SIZE_MB`: Maximum memory allocation
- `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`: MinIO connection

**Airbyte** (`abctl local credentials`):
- Run `abctl local credentials --email email@example.com` to change the email
- Run `abctl local credentials --password YourStrongPasswordExample` to change password

**Superset** (`superset/.env`):
- `SUPERSET_DB_USER`, `SUPERSET_DB_PASSWORD`: Superset metadata DB credentials
- `SUPERSET_ADMIN_USERNAME`, `SUPERSET_ADMIN_PASSWORD`: Superset admin login
- `SUPERSET_SECRET_KEY`: Secret key for session encryption

**Briefer** (`briefer/.env`):
- `BRIEFER_DB_USER`, `BRIEFER_DB_PASSWORD`: Briefer metadata DB credentials
- `BRIEFER_SECRET_KEY`, `BRIEFER_JWT_SECRET`: Security keys for authentication

### Security Notes
- **PRODUCTION WARNING**: The default credentials are for development only. Change all passwords before deploying to production:
1. Update all `.env` files with strong passwords
2. Regenerate Airflow Fernet key: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
3. Regenerate JWT secret: `openssl rand -hex 32`
4. Use environment-specific secrets management (AWS Secrets Manager, HashiCorp Vault, etc.)

## Resource Allocation
Default resource limits per service (can be adjusted in docker-compose.yml):
| Service | CPU Limit | Memory Limit | CPU Reservation | Memory Reservation |
|---------|-----------|--------------|-----------------|-------------------|
| Airflow Components | 2 cores | 2GB | 0.5 cores | 512MB |
| Airflow Postgres | 2 cores | 2GB | 0.5 cores | 512MB |
| MinIO | 2 cores | 2GB | 0.5 cores | 512MB |
| Dremio | 4 cores | 6GB | 2 cores | 4GB |
| Airbyte Components | 1-2 cores | 512MB-2GB | 0.1-0.5 cores | 128MB-512MB |
| Superset Components | 2 cores | 3GB | 0.5 cores | 1GB |
| Briefer | 2 cores | 3GB | 0.5 cores | 1GB |

**Total Recommended**: 20GB RAM, 12+ CPU cores (for all services)

## Common Operations
### Viewing Logs
```bash
# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f airflow-apiserver
docker-compose logs -f minio
docker-compose logs -f dremio
docker-compose logs -f airbyte-webapp
docker-compose logs -f superset
docker-compose logs -f briefer
```

### Stopping Services
```bash
# Stop all services
docker-compose --profile all down

# Stop specific service
docker-compose --profile airflow down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose --profile all down -v
```

### Restarting Services
```bash
# Restart all services
docker-compose --profile all restart

# Restart specific service
docker-compose restart minio
```
