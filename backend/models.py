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
