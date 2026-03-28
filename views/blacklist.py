from flask import request
from flask_restful import Resource
from marshmallow import ValidationError

from auth import token_required
from extensions import db
from models.blacklist import BlacklistEntry
from schemas.blacklist import BlacklistCreateSchema


class HealthResource(Resource):
    def get(self):
        return {'status': 'healthy'}, 200


class BlacklistResource(Resource):
    method_decorators = [token_required]

    def post(self):
        schema = BlacklistCreateSchema()
        try:
            data = schema.load(request.get_json(force=True) or {})
        except ValidationError as err:
            return {'message': 'Error de validación.', 'errors': err.messages}, 400

        entry = BlacklistEntry(
            email=data['email'],
            app_uuid=data['app_uuid'],
            blocked_reason=data.get('blocked_reason'),
            ip_address=request.remote_addr,
        )

        db.session.add(entry)
        db.session.commit()

        return {'message': 'Email agregado exitosamente a la lista negra.'}, 201


class BlacklistDetailResource(Resource):
    method_decorators = [token_required]

    def get(self, email):
        entry = (
            BlacklistEntry.query
            .filter_by(email=email)
            .order_by(BlacklistEntry.created_at.desc())
            .first()
        )

        if entry:
            return {'exist': True, 'blocked_reason': entry.blocked_reason}, 200

        return {'exist': False, 'blocked_reason': None}, 200
