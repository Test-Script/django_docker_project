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

