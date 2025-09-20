# ---------- Builder ----------
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Build tools + headers only in builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      gcc \
      libpq-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/

# Build wheels for all dependencies
RUN pip install --upgrade pip wheel \
 && pip wheel --wheel-dir /wheels -r requirements.txt

# If executable.sh builds assets (e.g., collectstatic/webpack), run here:
# COPY . /app
# RUN chmod +x ./executable.sh && ./executable.sh
# and then copy only the produced artifacts in the runtime stage.


# ---------- Runtime ----------
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Only runtime libs
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libpq5 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install from prebuilt wheels (no compilers in final image)
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* \
 && rm -rf /wheels

# Copy app code last for better caching
COPY --chown=10001:10001 . /app

# If executable.sh only prepares runtime artifacts, keep it in builder instead.
# If it must be run at runtime image, do:
# RUN chmod +x ./executable.sh && ./executable.sh

RUN useradd -u 10001 -M -s /usr/sbin/nologin test

RUN chmod +x ./executable.sh && ./executable.sh

USER 10001

EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

