import uuid
from marshmallow import Schema, fields, validates, ValidationError


class BlacklistCreateSchema(Schema):
    email = fields.Email(required=True, error_messages={'required': 'El campo email es requerido.'})
    app_uuid = fields.Str(required=True, error_messages={'required': 'El campo app_uuid es requerido.'})
    blocked_reason = fields.Str(load_default=None, allow_none=True)

    @validates('app_uuid')
    def validate_app_uuid(self, value):
        try:
            uuid.UUID(str(value))
        except ValueError:
            raise ValidationError('app_uuid debe ser un UUID válido.')

    @validates('blocked_reason')
    def validate_blocked_reason(self, value):
        if value and len(value) > 255:
            raise ValidationError('blocked_reason no puede exceder 255 caracteres.')
