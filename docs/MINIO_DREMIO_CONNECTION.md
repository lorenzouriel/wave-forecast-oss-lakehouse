# MinIO and Dremio Connection Configuration Guide

This guide explains how to configure the connection between MinIO (S3-compatible storage) and Dremio (query engine) in the Wave Forecast OSS Lakehouse.

## Overview

MinIO serves as the S3-compatible object storage layer, while Dremio acts as the query engine that reads data from MinIO. The connection is already pre-configured in the docker-compose files, but this guide will help you understand and customize it.

### Configure MinIO Source in Dremio UI

Once both services are running, configure the connection in Dremio:

#### A. Access Dremio UI
1. Open browser: http://localhost:9047
2. On first launch, create admin account
3. Login with your credentials

#### B. Add MinIO as S3 Source
1. Click **"Add Source"** in the bottom left
2. Select **"Amazon S3"** from the list
3. Configure with these settings:

**General Tab:**
```
Name: lakehouse-minio
Description: MinIO object storage for lakehouse
```

**Connection Tab:**
```
Authentication: AWS Access Key
AWS Access Key ID: your-key
AWS Secret Access Key: your-key
```

**Advanced Options:**
```
✓ Enable compatibility mode
Root Path: /

Connection Properties:
  Key: fs.s3a.endpoint
  Value: minio:9000

  Key: fs.s3a.path.style.access
  Value: true

  Key: fs.s3a.connection.ssl.enabled
  Value: false
```

4. Click **"Save"**

#### C. Verify Connection
1. In Dremio UI, you should see "lakehouse-minio" in the sources list
2. Click on it to expand
3. You should see your buckets: `bronze`, `silver`, `gold`

## Testing the Connection
### Option 1: Upload Test Data via MinIO Console
1. Open MinIO Console: http://localhost:9001
2. Navigate to `bronze` bucket
3. Create a folder: `test/`
4. Upload a CSV or Parquet file
5. In Dremio, refresh the source and navigate to the file
6. Preview the data

### Option 2: Create Test Data via Dremio
```sql
-- In Dremio SQL Editor
CREATE TABLE lakehouse-minio.bronze.test_table AS
SELECT
    1 as id,
    'test' as name,
    CURRENT_TIMESTAMP as created_at;

-- Query it back
SELECT * FROM lakehouse-minio.bronze.test_table;
```
