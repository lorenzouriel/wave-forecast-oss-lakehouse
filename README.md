# OSS Lakehouse - Waves Forecast

## Repository Structure
```bash
wave-forecast-lakehouse
 ┣ airflow
 ┣ dbt
 ┣ api-serving
 ┣ notebooks
 ┣ mlflow
 ┣ minio_data (ignored)
 ┣ docs
 ┃ ┣ arquitetura.png
 ┃ ┗ readme.pdf
 ┣ docker-compose.yml
 ┣ README.md
 ┗ ROADMAP.md
```
## Architecture
> MinIO + Airflow + dbt + Dremio + Iceberg + MLflow + FastAPI

```bash
                 ┌────────────────────────────────────────────┐
                 │         Fontes de Dados Externas           │
                 │ Boias (NOAA), GFS/ECMWF, Satélite, APIs    │
                 └────────────────────────────────────────────┘
                                 │
                                 ▼
                      ┌──────────────────────┐
                      │ Ingestion (Airflow)  │
                      │ Python, APIs, FTP    │
                      └──────────────────────┘
                                 │
                                 ▼
          ┌────────────────────────────────────────────────────────┐
          │         Data Lake (MinIO + Apache Iceberg)             │
          │  ┌────────┐   ┌────────┐   ┌───────────┐   ┌────────┐ │
          │  │ Raw    │ → │ Bronze │ → │ Silver    │ → │ Gold   │ │
          │  │        │   │        │   │ Curado    │   │ Modelo │ │
          │  └────────┘   └────────┘   └───────────┘   └────────┘ │
          └────────────────────────────────────────────────────────┘
                     │             │                    │
          ┌──────────┘      ┌──────┘         ┌──────────┘
          ▼                 ▼                ▼
 ┌────────────────┐  ┌─────────────────┐ ┌─────────────────────┐
 │ Transformações  │  │ Engine de Query │ │ ML Engineering      │
 │ dbt + SQL       │  │ Dremio / Trino  │ │ Spark / MLflow      │
 └────────────────┘  └─────────────────┘ └─────────────────────┘
                                         │
                                         ▼
                              ┌─────────────────────┐
                              │ Modelo Deploy (API) │
                              │ FastAPI + Docker    │
                              └─────────────────────┘
                                         │
                                         ▼
                              ┌─────────────────────┐
                              │ Usuários / Dashboard│
                              │ Grafana / Streamlit │
                              └─────────────────────┘
```