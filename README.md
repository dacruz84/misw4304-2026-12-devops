# misw4304-2026-12-devops.

Microservicio REST en Python/Flask para la gestión de la lista negra global de emails. Permite agregar emails a la lista negra y consultar si un email está bloqueado.

---

## Requisitos previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y en ejecución.

No se requiere instalar Python, pip ni PostgreSQL.

---

## Levantar la aplicación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd misw4304-2026-12-devops
```

### 2. (Opcional) Cambiar el token de autorización

El token estático por defecto es `my-static-secret-token`. Para cambiarlo, editar la variable `STATIC_TOKEN` en `docker-compose.yml`:

```yaml
environment:
  STATIC_TOKEN: tu-token-secreto
```

### 3. Construir e iniciar los contenedores

```bash
docker compose up --build
```

Esto levanta dos contenedores:
- **`db`** — PostgreSQL 13 en el puerto `5432`
- **`api`** — la aplicación Flask en el puerto `5000`

> Las tablas se crean automáticamente al iniciar la API. No se requiere ningún paso adicional de migración.

La API queda disponible en `http://localhost:5000`.

### Detener los contenedores

```bash
docker compose down
```

Para detener **y eliminar los datos** de la base de datos:

```bash
docker compose down -v
```

### Ver logs en tiempo real

```bash
docker compose logs -f api
```

---

## Endpoints

### `POST /blacklists`

Agrega un email a la lista negra global.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "email": "blocked@example.com",
  "app_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "blocked_reason": "Envío masivo de spam detectado."
}
```

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `email` | String | Sí | Email a bloquear |
| `app_uuid` | String (UUID) | Sí | ID de la app cliente |
| `blocked_reason` | String (máx. 255) | No | Motivo del bloqueo |

**Respuesta exitosa `201`:**
```json
{
  "message": "Email agregado exitosamente a la lista negra."
}
```

---

### `GET /blacklists/<email>`

Consulta si un email está en la lista negra.

**Headers:**
```
Authorization: Bearer <token>
```

**Respuesta `200` — email bloqueado:**
```json
{
  "exist": true,
  "blocked_reason": "Envío masivo de spam detectado."
}
```

**Respuesta `200` — email no bloqueado:**
```json
{
  "exist": false,
  "blocked_reason": null
}
```

---

## Pruebas con Postman

Importar la colección ubicada en `postman/Blacklist_API.postman_collection.json`.

La colección incluye los siguientes escenarios:

| # | Escenario | Resultado esperado |
|---|---|---|
| 1 | POST — agregar email con token válido | `201` |
| 2 | POST — agregar email sin `blocked_reason` | `201` |
| 3 | POST — sin token de autorización | `401` |
| 4 | POST — token inválido | `401` |
| 5 | POST — falta campo `email` | `400` |
| 6 | POST — `app_uuid` no es un UUID válido | `400` |
| 7 | GET — email que existe en la lista negra | `200` `exist: true` |
| 8 | GET — email que no existe en la lista negra | `200` `exist: false` |
| 9 | GET — sin token de autorización | `401` |

Configurar las variables de la colección antes de ejecutar:

| Variable | Valor |
|---|---|
| `base_url` | `http://localhost:5000` |
| `token` | valor de `STATIC_TOKEN` en `.env` |

