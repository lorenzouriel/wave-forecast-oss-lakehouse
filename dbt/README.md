# dbt - Data Transformation Layer
This directory contains the dbt (data build tool) project for transforming raw data from the bronze layer through the silver layer (Data Vault 2.0) to the gold layer (One Big Tables / OBT).

## Architecture
```bash
Bronze (MinIO)
    ↓
Staging Views (Parse JSON)
    ↓
Silver (Data Vault - Parquet)
    ├── Hubs (Business Keys)
    ├── Links (Relationships)
    └── Satellites (Attributes)
    ↓
Gold (OBT - Parquet)
    ├── Fact Tables (Wave Forecasts)
    └── Dimension Tables (Users, Locations)
```

### Layers

1. **Bronze**: Raw data from Airbyte connections (Google Sheets, OpenWeather Marine API)
   - Materialization: `view`
   - Format: As loaded by Airbyte
   - Purpose: Source of truth, no transformations

2. **Silver**: Data Vault 2.0 modeling
   - Materialization: `incremental`
   - Format: `parquet`
   - Components:
     - **Hubs**: Business keys (surf spots, forecasts)
     - **Links**: Relationships between entities
     - **Satellites**: Descriptive attributes with history
   - Purpose: Normalized, historical, auditable data

3. **Gold**: One Big Tables (OBT) / Dimensional models
   - Materialization: `table`
   - Format: `parquet`
   - Purpose: Denormalized views for analytics and reporting

## Setup

### 1. Configure Dremio Connection

Edit [.env](./.env) with your Dremio credentials:

```bash
DREMIO_USER=admin
DREMIO_PASSWORD=your-password
DREMIO_HOST=dremio
DREMIO_PORT=9047
```

### 2. Build and Start dbt Container

From the root directory:

```bash
# Build dbt container
docker-compose build dbt

# Test connection
docker-compose run --rm dbt dbt debug

# Run all transformations
docker-compose run --rm dbt dbt run
```

## Usage

### Running dbt Commands

All dbt commands should be run through docker-compose:

```bash
# Test connection to Dremio
docker-compose run --rm dbt dbt debug

# Install dbt packages (if any)
docker-compose run --rm dbt dbt deps

# Run all models
docker-compose run --rm dbt dbt run

# Run specific layer
docker-compose run --rm dbt dbt run --select silver
docker-compose run --rm dbt dbt run --select gold

# Run specific model
docker-compose run --rm dbt dbt run --select hub_surf_spot

# Run tests
docker-compose run --rm dbt dbt test

# Generate documentation
docker-compose run --rm dbt dbt docs generate

# Serve documentation (then visit http://localhost:8080)
docker-compose run --rm -p 8080:8080 dbt dbt docs serve --port 8080
```

### Development Workflow

1. **Inspect Bronze Sources**: First, check what data is actually available in Dremio
   ```bash
   # Open Dremio at http://localhost:9047
   # Navigate to lakehouse-minio > bronze
   # Note the actual table/file names and schemas
   ```

2. **Update Source Definitions**: Edit [models/bronze/sources.yml](models/bronze/sources.yml) with actual table names

3. **Build Silver Layer**: Create/update Data Vault models in:
   - `models/silver/hubs/` - Business entities
   - `models/silver/links/` - Relationships
   - `models/silver/satellites/` - Descriptive attributes

4. **Build Gold Layer**: Create analytics-ready views in `models/gold/`

5. **Test and Document**: Add tests and documentation to YAML files

## Project Structure
```bash
dbt/
├── Dockerfile                  # dbt container with dremio adapter
├── docker-compose.yml          # dbt service definition
├── dbt_project.yml            # dbt project configuration
├── profiles.yml               # Dremio connection profile
├── .env                       # Environment variables
├── models/
│   ├── bronze/                # Source definitions
│   │   ├── sources.yml        # Bronze source tables
│   │   └── bronze.yml         # Bronze model docs
│   ├── silver/                # Data Vault layer
│   │   ├── hubs/              # Business keys
│   │   ├── links/             # Relationships
│   │   └── satellites/        # Descriptive attributes
│   └── gold/                  # Analytics layer (OBT)
├── macros/                    # Reusable SQL macros
│   └── data_vault_macros.sql  # Data Vault utilities
├── tests/                     # Data quality tests
├── analyses/                  # Ad-hoc queries
├── snapshots/                 # Type 2 SCD snapshots
└── seeds/                     # Static reference data
```
