import os


class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql://postgres:postgres@localhost:5432/blacklist_db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    STATIC_TOKEN = os.environ.get('STATIC_TOKEN', 'my-static-secret-token')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-secret-key')
