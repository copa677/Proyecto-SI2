FROM python:3.12

# Instala dependencias del sistema (usa netcat-openbsd)
RUN apt-get update && apt-get install -y \
    netcat-openbsd \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000