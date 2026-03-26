from dotenv import load_dotenv
load_dotenv()

from flask import Flask
from flask_restful import Api
from config import Config
from extensions import db, ma


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    ma.init_app(app)

    # Import models so SQLAlchemy registers them before create_all()
    from models.blacklist import BlacklistEntry  # noqa: F401

    api = Api(app)

    from views.blacklist import BlacklistResource, BlacklistDetailResource
    api.add_resource(BlacklistResource, '/blacklists')
    api.add_resource(BlacklistDetailResource, '/blacklists/<string:email>')

    with app.app_context():
        db.create_all()

    return app


app = create_app()
application = app  # AWS Elastic Beanstalk expects the WSGI callable to be named 'application'

if __name__ == '__main__':
    app.run(debug=False)
