"""
Airbyte ETL DAG - Multi-Source to MinIO
This DAG triggers Airbyte sync jobs to extract data from multiple sources
and load them into MinIO (bronze layer).

Sources:
- Google Sheets -> MinIO (bronze)
- Open Weather Marine -> MinIO (bronze)
"""

from datetime import datetime, timedelta
from airflow.decorators import dag
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.airbyte.sensors.airbyte import AirbyteJobSensor

# Default arguments for the DAG
default_args = {
    'owner': 'lorenzo',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

@dag(
    dag_id='airbyte_multi_source_to_minio',
    default_args=default_args,
    description='ETL pipeline: Multiple sources -> MinIO (Bronze Layer)',
    start_date=datetime(2025, 1, 1),
    schedule='@daily',
    catchup=False,
    tags=['airbyte', 'etl', 'google-sheets', 'open-weather-marine', 'minio', 'bronze'],
)
def airbyte_etl_pipeline():
    """
    DAG to sync data from multiple sources to MinIO using Airbyte.
    Runs both connections in parallel.
    """

    # Google Sheets -> MinIO sync
    trigger_google_sheets_sync = AirbyteTriggerSyncOperator(
        task_id='trigger_google_sheets_sync',
        airbyte_conn_id='airbyte_default',
        connection_id='{{ var.value.airbyte_google_sheets_connection_id }}',
        asynchronous=True,
    )

    wait_google_sheets_completion = AirbyteJobSensor(
        task_id='wait_google_sheets_completion',
        airbyte_conn_id='airbyte_default',
        airbyte_job_id=trigger_google_sheets_sync.output,
        timeout=3600,
        poke_interval=60,
    )

    # Open Weather Marine -> MinIO sync
    trigger_open_weather_sync = AirbyteTriggerSyncOperator(
        task_id='trigger_open_weather_sync',
        airbyte_conn_id='airbyte_default',
        connection_id='{{ var.value.airbyte_open_weather_connection_id }}',
        asynchronous=True,
    )

    wait_open_weather_completion = AirbyteJobSensor(
        task_id='wait_open_weather_completion',
        airbyte_conn_id='airbyte_default',
        airbyte_job_id=trigger_open_weather_sync.output,
        timeout=3600,
        poke_interval=60,
    )

    # Define task dependencies - both syncs run in parallel
    trigger_google_sheets_sync >> wait_google_sheets_completion
    trigger_open_weather_sync >> wait_open_weather_completion


# Instantiate the DAG
airbyte_etl_dag = airbyte_etl_pipeline()
