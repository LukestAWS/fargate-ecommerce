# Stage 1: Builder
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
# Install dependencies to the standard location
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Final
FROM python:3.12-slim
WORKDIR /app

# Copy ONLY the installed library files from the builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
# Copy the uvicorn executable
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy your application code
COPY . .

ENV PYTHONUNBUFFERED=1
EXPOSE 8000

# Install curl for the healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]