# Use an official Python runtime as a parent image
FROM python:3.13.3-slim-bookworm

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY requirements.txt .
RUN uv pip install --no-cache-dir -r requirements.txt --system

# Copy project
COPY . .

# Collect static files (requires distinct SECRET_KEY for build or dummy)
RUN python manage.py collectstatic --noinput --clear --dry-run || echo "Run collectstatic at runtime if DB needed"

# Create a non-root user and switch to it
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Expose port
EXPOSE 8000

CMD ["./entrypoint.sh"]
