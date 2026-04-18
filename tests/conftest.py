"""
conftest.py — Se ejecuta ANTES de importar cualquier módulo de la aplicación.

Configura variables de entorno para que la app use SQLite en memoria
en lugar de PostgreSQL, eliminando la dependencia de BD externa en CI.
"""
import os

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["STATIC_TOKEN"] = "test-static-token"
os.environ["JWT_SECRET_KEY"] = "test-jwt-secret"
