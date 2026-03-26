import os


def _build_db_uri():
    # AWS Elastic Beanstalk injects RDS_* variables automatically when a
    # database is attached to the environment.
    rds_host = os.environ.get('RDS_HOSTNAME')
    if rds_host:
        return (
            f"postgresql://{os.environ['RDS_USERNAME']}:{os.environ['RDS_PASSWORD']}"
            f"@{rds_host}:{os.environ.get('RDS_PORT', '5432')}/{os.environ['RDS_DB_NAME']}"
        )
    # Fallback: explicit DATABASE_URL or local default
    return os.environ.get(
        'DATABASE_URL',
        'postgresql://postgres:postgres@localhost:5432/blacklist_db'
    )


class Config:
    SQLALCHEMY_DATABASE_URI = _build_db_uri()
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    STATIC_TOKEN = os.environ.get('STATIC_TOKEN', 'my-static-secret-token')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-secret-key')
