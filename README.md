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

## 文件结构
medical-app/
├─ docker-compose.yml
├─ .env.example
├─ README.md
├─ backend/
│ ├─ requirements.txt
│ ├─ app.py
│ ├─ config.py
│ ├─ models.py
│ ├─ routes/
│ │ ├─ __init__.py
│ │ ├─ doctors.py
│ │ ├─ appointments.py
│ │ ├─ webhooks.py # Dify/Coze 回调入口
│ ├─ utils/
│ │ ├─ scheduler.py # Top-K 医生匹配（简化版）
│ │ └─ notify.py # 推送占位
│ └─ migrations/ # Alembic 自动生成
└─ scripts/
└─ init_dev.sh