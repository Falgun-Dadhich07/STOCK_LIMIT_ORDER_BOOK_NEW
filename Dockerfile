FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy entrypoint script early so it is available at a stable layer
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copy project files
COPY . .

# Set working directory to Django project
WORKDIR /app/trading_system

# Collect static files (whitenoise serves them, no DB needed for this step)
RUN SECRET_KEY=collectstatic-build-only python manage.py collectstatic --noinput || true

# Expose port (Railway sets PORT dynamically)
EXPOSE ${PORT:-8000}

# Start via entrypoint script (runs migrations + creates superuser + starts Daphne)
CMD ["/app/entrypoint.sh"]
