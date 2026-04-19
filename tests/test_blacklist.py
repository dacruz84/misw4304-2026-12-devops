"""
Pruebas unitarias para los endpoints de la API de Blacklist.
Usa SQLite en memoria (configurado en conftest.py) para no depender
de PostgreSQL en el entorno de CI.
"""
import pytest
from application import create_app
from extensions import db as _db
from models.blacklist import BlacklistEntry


# ---------------------------------------------------------------------------
# Configuración de pruebas
# ---------------------------------------------------------------------------

class TestConfig:
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    STATIC_TOKEN = "test-static-token"
    JWT_SECRET_KEY = "test-jwt-secret"


@pytest.fixture(scope="session")
def app():
    """Crea la app Flask con base de datos SQLite en memoria."""
    _app = create_appdtyrtyreyttey(TestConfig)
    with _app.app_context():
        _db.create_all()
        yield _app
        _db.drop_all()


@pytest.fixture
def client(app):
    """Cliente HTTP de pruebas."""
    return app.test_client()


@pytest.fixture(autouse=True)
def clean_db(app):
    """Limpia las tablas antes de cada prueba para que sean independientes."""
    with app.app_context():
        _db.session.query(BlacklistEntry).delete()
        _db.session.commit()
    yield


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

AUTH = {"Authorization": "Bearer test-static-token"}
INVALID_AUTH = {"Authorization": "Bearer token-invalido"}

VALID_PAYLOAD = {
    "email": "test@example.com",
    "app_uuid": "123e4567-e89b-12d3-a456-426614174000",
    "blocked_reason": "Spam"
}


# ---------------------------------------------------------------------------
# GET /health
# ---------------------------------------------------------------------------

class TestHealth:

    def test_health_retorna_200(self, client):
        """El endpoint /health debe responder 200."""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_retorna_status_healthy(self, client):
        """El cuerpo de /health debe indicar que el servicio está activo."""
        response = client.get("/health")
        data = response.get_json()
        assert data["status"] == "healthy"


# ---------------------------------------------------------------------------
# POST /blacklists
# ---------------------------------------------------------------------------

class TestBlacklistPost:

    def test_post_sin_token_retorna_401(self, client):
        """POST sin token debe ser rechazado con 401."""
        response = client.post("/blacklists", json=VALID_PAYLOAD)
        assert response.status_code == 401

    def test_post_token_invalido_retorna_401(self, client):
        """POST con token incorrecto debe retornar 401."""
        response = client.post("/blacklists", json=VALID_PAYLOAD, headers=INVALID_AUTH)
        assert response.status_code == 401

    def test_post_exitoso_retorna_201(self, client):
        """POST con datos válidos y token correcto debe retornar 201."""
        response = client.post("/blacklists", json=VALID_PAYLOAD, headers=AUTH)
        assert response.status_code == 201

    def test_post_exitoso_retorna_mensaje(self, client):
        """La respuesta del POST exitoso debe incluir un mensaje."""
        response = client.post("/blacklists", json=VALID_PAYLOAD, headers=AUTH)
        data = response.get_json()
        assert "message" in data

    def test_post_sin_email_retorna_400(self, client):
        """POST sin campo email debe retornar 400."""
        payload = {"app_uuid": "123e4567-e89b-12d3-a456-426614174000"}
        response = client.post("/blacklists", json=payload, headers=AUTH)
        assert response.status_code == 400

    def test_post_email_invalido_retorna_400(self, client):
        """POST con email mal formado debe retornar 400."""
        payload = {**VALID_PAYLOAD, "email": "no-es-un-email"}
        response = client.post("/blacklists", json=payload, headers=AUTH)
        assert response.status_code == 400

    def test_post_uuid_invalido_retorna_400(self, client):
        """POST con app_uuid que no es UUID válido debe retornar 400."""
        payload = {**VALID_PAYLOAD, "app_uuid": "no-es-uuid"}
        response = client.post("/blacklists", json=payload, headers=AUTH)
        assert response.status_code == 400

    def test_post_sin_blocked_reason_retorna_201(self, client):
        """El campo blocked_reason es opcional; omitirlo debe ser válido."""
        payload = {
            "email": "sinrazon@example.com",
            "app_uuid": "123e4567-e89b-12d3-a456-426614174000"
        }
        response = client.post("/blacklists", json=payload, headers=AUTH)
        assert response.status_code == 201


# ---------------------------------------------------------------------------
# GET /blacklists/<email>
# ---------------------------------------------------------------------------

class TestBlacklistGet:

    def test_get_sin_token_retorna_401(self, client):
        """GET sin token debe ser rechazado con 401."""
        response = client.get("/blacklists/alguien@example.com")
        assert response.status_code == 401

    def test_get_token_invalido_retorna_401(self, client):
        """GET con token incorrecto debe retornar 401."""
        response = client.get("/blacklists/alguien@example.com", headers=INVALID_AUTH)
        assert response.status_code == 401

    def test_get_email_no_bloqueado_retorna_exist_false(self, client):
        """Consultar email que no está en la lista debe retornar exist=False."""
        response = client.get("/blacklists/noexiste@example.com", headers=AUTH)
        assert response.status_code == 200
        data = response.get_json()
        assert data["exist"] is False
        assert data["blocked_reason"] is None

    def test_get_email_bloqueado_retorna_exist_true(self, client):
        """Consultar email bloqueado debe retornar exist=True."""
        client.post("/blacklists", json=VALID_PAYLOAD, headers=AUTH)

        response = client.get("/blacklists/test@example.com", headers=AUTH)
        assert response.status_code == 200
        data = response.get_json()
        assert data["exist"] is True

    def test_get_email_bloqueado_retorna_blocked_reason(self, client):
        """Consultar email bloqueado debe retornar su blocked_reason."""
        client.post("/blacklists", json=VALID_PAYLOAD, headers=AUTH)

        response = client.get("/blacklists/test@example.com", headers=AUTH)
        data = response.get_json()
        assert data["blocked_reason"] == "Spam"
