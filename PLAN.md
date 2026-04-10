# Plan de Implementación — Microservicio Blacklist de Emails

Microservicio REST en **Python/Flask** para gestionar una lista negra global de emails. Autenticación con Bearer Token estático. Persistencia en **PostgreSQL**.

---

## Stack tecnológico (requerido)

| Tecnología | Versión | Rol |
|---|---|---|
| Python | 3.8+ | Lenguaje |
| Flask | 1.1.x | Framework web |
| Flask-SQLAlchemy | 2.5.x | ORM |
| Flask-RESTful | 0.3.x | API REST orientada a objetos |
| Flask-Marshmallow | 0.14.x | Serialización |
| Flask-JWT-Extended | 3.x | Soporte JWT / tokens |
| Werkzeug | 1.0.x | WSGI |
| PostgreSQL | 13+ | Base de datos relacional |

---

## Estructura del proyecto

```
misw4304-2026-12-devops/
├── PLAN.md
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── Dockerfile
├── config.py          # Configuración de la aplicación
├── extensions.py      # Instancias de extensiones Flask (db, ma)
├── application.py     # App factory + punto de entrada
├── auth.py            # Decorador de autenticación Bearer Token
├── models/
│   ├── __init__.py
│   └── blacklist.py   # Modelo BlacklistEntry (SQLAlchemy)
├── schemas/
│   ├── __init__.py
│   └── blacklist.py   # Schemas de validación (Marshmallow)
├── views/
│   ├── __init__.py
│   └── blacklist.py   # Recursos REST (Flask-RESTful)
└── postman/
    └── Blacklist_API.postman_collection.json
```

---

## Endpoints

### POST `/blacklists`
Agrega un email a la lista negra global.

- **Autorización**: `Authorization: Bearer <token>`
- **Body JSON**:
  - `email` (String, requerido)
  - `app_uuid` (String UUID, requerido)
  - `blocked_reason` (String, opcional, máx. 255 chars)
- **Internamente guarda**: IP del solicitante + fecha/hora
- **Retorno**: `200 OK` — mensaje de confirmación

### GET `/blacklists/<string:email>`
Consulta si un email está en la lista negra.

- **Autorización**: `Authorization: Bearer <token>`
- **Retorno**: `200 OK` — `{ "exist": true/false, "blocked_reason": "..." }`

---

## Modelo de datos — `BlacklistEntry`

| Campo | Tipo | Restricciones |
|---|---|---|
| `id` | Integer | PK, autoincrement |
| `email` | String(255) | not null, index |
| `app_uuid` | String(36) | not null |
| `blocked_reason` | String(255) | nullable |
| `ip_address` | String(45) | not null |
| `created_at` | DateTime | not null, default=utcnow |

---

## Autenticación

Token estático definido en variable de entorno `STATIC_TOKEN`. Se valida en cada request mediante un decorador `@token_required` en `auth.py`. Comparación segura con `hmac.compare_digest` para evitar timing attacks.

---

## Fases de implementación

- [x] **Fase 1**: PLAN.md
- [ ] **Fase 2**: `requirements.txt`, `.env.example`, `config.py`
- [ ] **Fase 3**: `extensions.py`, `application.py`
- [ ] **Fase 4**: `auth.py`
- [ ] **Fase 5**: `models/blacklist.py`, `schemas/blacklist.py`
- [ ] **Fase 6**: `views/blacklist.py`
- [ ] **Fase 7**: Colección Postman
- [ ] **Fase 8**: `Dockerfile`, `.gitignore`

---

## Verificación local

```bash
# 1. Levantar PostgreSQL
docker run --name blacklist-db -e POSTGRES_PASSWORD=pass -e POSTGRES_DB=blacklist_db -p 5432:5432 -d postgres:13

# 2. Configurar variables de entorno
cp .env.example .env
# editar .env con la URI de BD y el token estático

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Ejecutar la aplicación
flask run
```

### Escenarios de prueba

| # | Acción | Esperado |
|---|---|---|
| 1 | POST `/blacklists` con token válido | `200` mensaje de éxito |
| 2 | POST `/blacklists` sin token | `401` |
| 3 | POST `/blacklists` con token inválido | `401` |
| 4 | POST `/blacklists` sin `email` | `400` error de validación |
| 5 | POST `/blacklists` con `app_uuid` inválido | `400` error de validación |
| 6 | GET `/blacklists/<email>` existente | `200` `{ "exist": true, ... }` |
| 7 | GET `/blacklists/<email>` no existente | `200` `{ "exist": false }` |
| 8 | GET `/blacklists/<email>` sin token | `401` |

---

## Decisiones de diseño

- El token Bearer es **estático** (comparación directa contra `STATIC_TOKEN`)
- Se permiten múltiples entradas para el mismo email (distintas apps)
- En GET, se retorna la entrada más reciente para ese email
- La IP se obtiene de `request.remote_addr`
- `app_uuid` se valida como UUID v4 válido en el schema
