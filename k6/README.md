# Pruebas de Estrés con k6

Pruebas de estrés para el microservicio **Blacklist API** usando [k6](https://k6.io/).

## Requisitos

Instala k6 según tu sistema operativo:

**Windows (Chocolatey):**
```powershell
choco install k6
```

**Windows (winget):**
```powershell
winget install k6 --source winget
```

**macOS:**
```bash
brew install k6
```

**Linux (Debian/Ubuntu):**
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

Verifica la instalación:
```bash
k6 version
```

---

## Estructura de tu Infraestructura

El script está calibrado para la siguiente configuración real del servicio:

| Parámetro | Valor |
|---|---|
| Tareas ECS | 1 (`desired_count = 1`) |
| CPU | 0.25 vCPU (256 unidades) |
| Memoria | 512 MB |
| Workers Gunicorn | 1 (valor por defecto, sin flag `--workers`) |
| Backend | PostgreSQL en Amazon RDS |

> **Nota sobre el worker único:** Con 1 solo worker de Gunicorn, los requests
> se procesan de forma **secuencial**. La capacidad teórica máxima es
> aproximadamente:
>
> $$RPM \approx \frac{60}{avg\_response\_time\_seg}$$
>
> Con un tiempo de respuesta promedio de 300ms en `POST /blacklists` (escribe
> en RDS), el límite teórico es **~200 RPM (~3 req/seg)**. La prueba de estrés
> te mostrará el punto exacto donde la latencia se dispara.

---

## Ejecutar la Prueba

### Contra el entorno local (Docker Compose)

Levanta la aplicación localmente primero:
```bash
docker-compose up -d
```

Luego ejecuta la prueba:
```powershell
k6 run .\k6\stress-test.js `
  -e BASE_URL=http://localhost:5000 `
  -e TOKEN=my-static-secret-token
```

### Contra el entorno de AWS (ECS Fargate)

```powershell
k6 run .\k6\stress-test.js `
  -e BASE_URL=http://<ALB-URL-O-IP-PUBLICA> `
  -e TOKEN=my-static-secret-token
```

Reemplaza `<ALB-URL-O-IP-PUBLICA>` con la URL de tu Application Load Balancer
o la IP pública de tu tarea ECS.

---

## Fases de la Prueba

| Fase | Duración | VUs | Objetivo |
|---|---|---|---|
| 1 — Baseline | 1 min | 2 | Verificar que el servicio responde correctamente |
| 2 — Carga normal | 2 min | 5 | Simular uso cotidiano |
| 3 — Carga alta | 3 min | 10 | Empujar al límite del worker único |
| 4 — Estrés | 3 min | 20 | Forzar saturación (se esperan errores/timeouts) |
| 5 — Pico extremo | 2 min | 40 | Encontrar el punto de quiebre |
| 6 — Recuperación | 2 min | 0 | Verificar que el servicio se recupera |

**Duración total: ~13 minutos**

---

## Endpoints Evaluados

Cada VU (usuario virtual) ejecuta este flujo en cada iteración:

1. `POST /blacklists` — Agrega un email único a la lista negra
2. `GET /blacklists/<email>` — Consulta el email recién agregado
3. `GET /health` — Verifica que el servicio sigue respondiendo

---

## Umbrales de Éxito (Thresholds)

La prueba **pasa** si se cumplen todas estas condiciones:

| Métrica | Umbral |
|---|---|
| Tasa de errores general | < 10% |
| P95 de `POST /blacklists` | < 2000 ms |
| P95 de `GET /blacklists/<email>` | < 1000 ms |
| Tasa de fallos HTTP | < 10% |

Si algún umbral no se cumple, k6 termina con **exit code 99**.

---

## Interpretar los Resultados

Al finalizar, k6 muestra un resumen como este:

```
✓ POST /blacklists → 201
✓ GET /blacklists/<email> → 200
✗ GET responde exist=true

checks.........................: 94.20%  ✓ 1884  ✗ 116
data_received..................: 1.2 MB  1.5 kB/s
data_sent......................: 890 kB  1.1 kB/s
error_rate.....................: 5.80%   ✓ 0
get_blacklist_duration.........: avg=245ms  p(95)=890ms
http_req_duration..............: avg=310ms  p(50)=220ms  p(95)=1.1s  p(99)=3.2s
http_req_failed................: 5.80%   ✓ 0  ✗ 116
post_blacklist_duration........: avg=380ms  p(95)=1.8s
vus............................: 40      min=0  max=40
```

**Qué buscar:**
- **`p(95)` de duración**: si salta a >2s en estrés, encontraste el cuello de botella
- **`error_rate`**: si supera 10% en una fase específica, ahí está el punto de quiebre
- **Latencia en Fase 3 vs Fase 4**: el salto de latencia entre 10 y 20 VUs te dice cuándo el único worker se satura

---

## Ver Resultados en New Relic

Durante la prueba, monitorea tu aplicación en New Relic (ya configurado con `newrelic.ini`):

1. Abre **APM > Blacklist API**
2. Revisa **Throughput** (req/min) y **Response time**
3. En **Distributed Tracing** verás las transacciones lentas por endpoint
4. En **Errors** verás los 500 que ocurran durante las fases de estrés

---

## Exportar Resultados a JSON

```powershell
k6 run .\k6\stress-test.js `
  -e BASE_URL=http://localhost:5000 `
  -e TOKEN=my-static-secret-token `
  --out json=.\k6\results.json
```

El archivo `results.json` contiene cada métrica punto a punto para análisis posterior.
