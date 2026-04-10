import hmac
from functools import wraps
from flask import request, current_app
from flask_restful import abort


def token_required(f):
    """Decorator that validates a static Bearer token on every request."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')

        if not auth_header.startswith('Bearer '):
            abort(401, message='Token de autorización requerido.')

        token = auth_header[len('Bearer '):]
        static_token = current_app.config.get('STATIC_TOKEN', '')

        if not hmac.compare_digest(token, static_token):
            abort(401, message='Token de autorización inválido.')

        return f(*args, **kwargs)
    return decorated
