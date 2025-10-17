#!/bin/bash
set -e

echo "Building medical-app structure..."

mkdir -p {backend/{routes,utils,migrations},scripts}

cat > .env.example <<'EOF'
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=medapp
DB_PASS=medapp123
DB_NAME=medapp
REDIS_URL=redis://localhost:6379/0
FLASK_ENV=development
SECRET_KEY=dev-secret
WEBHOOK_TOKEN=change-me
EOF

cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    container_name: medapp-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: medapp
      MYSQL_USER: medapp
      MYSQL_PASSWORD: medapp123
    ports:
      - "3306:3306"
    command: ["--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:7
    container_name: medapp-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
volumes:
  db_data:
EOF

cat > backend/requirements.txt <<'EOF'
flask==3.0.3
flask-cors==4.0.1
flask-migrate==4.0.7
SQLAlchemy==2.0.35
pymysql==1.1.1
redis==5.0.8
python-dotenv==1.0.1
requests==2.32.3
EOF

cat > backend/config.py <<'EOF'
import os
from dotenv import load_dotenv
load_dotenv()

class Config:
    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{os.getenv('DB_USER')}:{os.getenv('DB_PASS')}@"
        f"{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}?charset=utf8mb4"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret")
    REDIS_URL = os.getenv("REDIS_URL")
    WEBHOOK_TOKEN = os.getenv("WEBHOOK_TOKEN", "change-me")
EOF

cat > backend/app.py <<'EOF'
from flask import Flask
from flask_migrate import Migrate
from flask_cors import CORS
from .config import Config
from .models import db

migrate = Migrate()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)
    db.init_app(app)
    migrate.init_app(app, db)

    from .routes import register_routes
    register_routes(app)

    @app.get("/health")
    def health():
        return {"status": "ok"}

    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=8000, debug=True)
EOF

cat > backend/models.py <<'EOF'
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

class TimestampMixin:
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class User(db.Model, TimestampMixin):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    openid = db.Column(db.String(64), unique=True, index=True)
    name = db.Column(db.String(64))
    phone = db.Column(db.String(20), index=True)

class Doctor(db.Model, TimestampMixin):
    __tablename__ = 'doctors'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(64), nullable=False)
    specialty = db.Column(db.String(64))
    level = db.Column(db.String(32))
    clinic_location = db.Column(db.String(128))

class Schedule(db.Model, TimestampMixin):
    __tablename__ = 'schedules'
    id = db.Column(db.Integer, primary_key=True)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    capacity = db.Column(db.Integer, default=5)
    booked = db.Column(db.Integer, default=0)

class Appointment(db.Model, TimestampMixin):
    __tablename__ = 'appointments'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    schedule_id = db.Column(db.Integer, db.ForeignKey('schedules.id'))
    status = db.Column(db.String(20), default='pending')
    reason = db.Column(db.String(255))

class AIReport(db.Model, TimestampMixin):
    __tablename__ = 'ai_reports'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    raw_result = db.Column(db.JSON)

class TaskLog(db.Model, TimestampMixin):
    __tablename__ = 'task_logs'
    id = db.Column(db.Integer, primary_key=True)
    source = db.Column(db.String(32))
    event = db.Column(db.String(64))
    payload = db.Column(db.JSON)
    status = db.Column(db.String(20), default='received')
EOF

mkdir -p backend/routes backend/utils
touch backend/routes/__init__.py backend/routes/doctors.py backend/routes/appointments.py backend/routes/webhooks.py
touch backend/utils/scheduler.py backend/utils/notify.py

cat > README.md <<'EOF'
# medical-app between doc and patient using agent AI

## 快速启动
```bash
docker compose up -d
cd backend
pip install -r requirements.txt
flask --app backend.app:create_app db init
flask --app backend.app:create_app db migrate -m "init"
flask --app backend.app:create_app db upgrade
python -m backend.app
