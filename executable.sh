#!/bin/bash

chown test:test /app/db.sqlite3
chown test:test /app
chmod 664 /app/db.sqlite3
chmod 775 /app

python3 manage.py makemigrations

python3 manage.py migrate
