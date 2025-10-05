The error OperationalError at /admin/login/

means your **SQLite database file is not writable by Django**. This is common when running Django inside Docker, on Linux servers, or with incorrect file permissions.

Here’s how you can fix it:

### 🔎 Why it happens

1. **SQLite file permissions** – The `db.sqlite3` file (or your DB file) is owned by a user that Django’s process cannot write to.
2. **Directory permissions** – SQLite needs not only write access to the file, but also to the containing directory (for temp journal files).
3. **Read-only filesystem** – If your server mounts `/app` (or wherever DB lives) as read-only, you can’t write to it.

✅ Steps to fix

1. Check where your DB is

Usually it’s in your project root:


ls -l /app/db.sqlite3


2. Fix ownership and permissions

If your Django app runs as `www-data` or `django`, grant ownership:


# Replace 'www-data' with your Django run user
chown www-data:www-data /app/db.sqlite3
chown www-data:www-data /app
chmod 664 /app/db.sqlite3
chmod 775 /app


#### 3. If using Docker

Make sure your **volume mount** is not read-only. For example:

❌ Wrong:

yaml

volumes:
  - ./app:/app:ro


✅ Correct:

yaml

volumes:
  - ./app:/app:rw

#### 4. If you’re deploying to production

SQLite is **not recommended for production**. Multiple processes (gunicorn, uwsgi, etc.) can cause locking issues. Switch to PostgreSQL or MySQL if this is a deployed app.

⚡ Quick test:
After fixing permissions, try running:

python manage.py migrate

-----------------------------------------------

https://43.204.238.24:9443

http://43.204.238.24:8080



docker run -d --name django_db -p 3306:3306 -e MYSQL_ROOT_PASSWORD=admin  mysql

MYSQL_ROOT_PASSWORD : admin

MYSQL_DATABASE : test_db

MYSQL_USER : root

MYSQL_PASSWORD : admin

MYSQL_ALLOW_EMPTY_PASSWORD

MYSQL_RANDOM_ROOT_PASSWORD

---------------------------
MYSQL_USER : root

MYSQL_PASSWORD : admin

MYSQL_DATABASE : test_db

CREATE DATABASE test_db;

USE test_db;

mysql -u root -p

mysql -h 172.17.0.3 -P 3306 -u root -p

---------------------------

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'test_db',           # your MySQL database name
        'USER': 'root',         # your MySQL username
        'PASSWORD': 'admin',     # your MySQL password
        'HOST': '127.0.0.1',            # or 'db' if using Docker Compose service name
        'PORT': '3306',                 # default MySQL port
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
        },
    }
}

-----------------------------

docker run -d \
  --name django_db \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=admin \
  -e MYSQL_DATABASE=test_db \
  -e MYSQL_USER=django_user \
  -e MYSQL_PASSWORD=django_pass \
  mysql

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'test_db',
        'USER': 'django_user',
        'PASSWORD': 'django_pass',
        'HOST': '127.0.0.1',
        'PORT': '3306',
    }
}

-------------------------------

ubuntu@ip-172-31-3-91:~/django_docker_project$ cat Dockerfile
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

--------------- Error ------------------------

#!/bin/sh
python manage.py makemigrations --noinput
python manage.py migrate --noinput
python manage.py collectstatic --noinput
exec "$@"

