# ---------- Builder ----------
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Build tools + MySQL headers for mysqlclient
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      gcc \
      default-libmysqlclient-dev \
      pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/

# Build wheels for all dependencies
RUN pip install --upgrade pip wheel \
 && pip wheel --wheel-dir /wheels -r requirements.txt


# ---------- Runtime ----------
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Runtime MySQL client libs only (no compilers, no headers)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      default-libmysqlclient-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install from prebuilt wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* \
 && rm -rf /wheels

# Copy app code last for better caching
COPY --chown=10001:10001 . /app

RUN useradd -u 10001 -M -s /usr/sbin/nologin test
#RUN chmod +x ./executable.sh && ./executable.sh

COPY ./executable.sh /app/executable.sh

RUN chmod +x /app/executable.sh

ENTRYPOINT ["/app/executable.sh"]

USER 10001

EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

