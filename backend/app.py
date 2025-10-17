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
