FROM python:3.11.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/app/dbt

# Install dbt-core and dbt-dremio adapter
RUN pip install --no-cache-dir \
    dbt-core==1.8.0 \
    dbt-dremio==1.8.2

# Copy dbt project files
COPY . .

# Set environment variables
ENV DBT_PROFILES_DIR=/usr/app/dbt

# Create logs directory
RUN mkdir -p logs

# Default command
CMD ["dbt", "debug"]
