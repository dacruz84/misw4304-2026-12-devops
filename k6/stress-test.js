/**
 * Prueba de estrés — Blacklist API
 *
 * Infraestructura objetivo:
 *   - 1 tarea ECS Fargate (desired_count = 1)
 *   - 0.25 vCPU / 512 MB RAM
 *   - 1 worker Gunicorn (valor por defecto, sin flag --workers)
 *   - Backend: PostgreSQL en RDS
 *
 * Con 1 solo worker, Gunicorn procesa requests de forma secuencial.
 * Capacidad teórica estimada:
 *   RPM ≈ 60 / avg_response_time_seg
 *   Ej: si avg = 300ms → RPM ≈ 200 req/min ≈ ~3 req/seg
 *
 * Ejecutar:
 *   k6 run stress-test.js -e BASE_URL=http://<tu-url> -e TOKEN=<tu-token>
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ---------------------------------------------------------------------------
// Métricas personalizadas
// ---------------------------------------------------------------------------
const errorRate    = new Rate('error_rate');
const postDuration = new Trend('post_blacklist_duration', true);
const getDuration  = new Trend('get_blacklist_duration', true);

// ---------------------------------------------------------------------------
// Variables de entorno (pasar con -e KEY=VALUE al ejecutar)
// ---------------------------------------------------------------------------
const BASE_URL = __ENV.BASE_URL || 'http://35.175.187.95:5000';
const TOKEN    = __ENV.TOKEN    || 'my-static-secret-token';

const HEADERS = {
  Authorization: `Bearer ${TOKEN}`,
  'Content-Type': 'application/json',
};

// ---------------------------------------------------------------------------
// Fases del stress test
// ---------------------------------------------------------------------------
// Con 1 worker y 0.25 vCPU el punto de saturación es bajo.
// Empezamos con muy poca carga y escalamos gradualmente para observar
// en qué punto la latencia se dispara y empiezan los errores.
// ---------------------------------------------------------------------------
export const options = {
  stages: [
    // Fase 1 — Baseline: carga mínima para verificar que todo funciona
    { duration: '1m', target: 2 },

    // Fase 2 — Carga normal esperada: ~5 usuarios concurrentes
    { duration: '2m', target: 5 },

    // Fase 3 — Carga alta: empujamos al límite del worker único
    { duration: '3m', target: 10 },

    // Fase 4 — Estrés real: forzamos saturación (esperamos errores/timeouts)
    { duration: '3m', target: 20 },

    // Fase 5 — Pico extremo: punto de quiebre
    { duration: '2m', target: 40 },

    // Fase 6 — Recuperación: bajamos la carga para ver si el servicio se recupera
    { duration: '2m', target: 0 },
  ],

  thresholds: {
    // Menos del 10% de errores HTTP en toda la prueba
    error_rate: ['rate<0.10'],

    // El 95% de los POST deben responder en menos de 2 segundos
    post_blacklist_duration: ['p(95)<2000'],

    // El 95% de los GET deben responder en menos de 1 segundo
    get_blacklist_duration: ['p(95)<1000'],

    // Tasa general de fallos HTTP
    http_req_failed: ['rate<0.10'],
  },
};

// ---------------------------------------------------------------------------
// Función principal — se ejecuta una vez por VU (usuario virtual) por iteración
// ---------------------------------------------------------------------------
export default function () {
  const vuId    = __VU;        // ID del usuario virtual (1, 2, 3...)
  const iterNum = __ITER;      // Número de iteración del VU actual

  // POST /blacklists — agregar email a la lista negra
  const email   = `stress-vu${vuId}-iter${iterNum}@test.com`;
  const postRes = http.post(
    `${BASE_URL}/blacklists`,
    JSON.stringify({
      email:          email,
      app_uuid:       '550e8400-e29b-41d4-a716-446655440000',
      blocked_reason: `Stress test VU=${vuId} iter=${iterNum}`,
    }),
    { headers: HEADERS, tags: { endpoint: 'post_blacklist' } }
  );

  postDuration.add(postRes.timings.duration);
  const postOk = check(postRes, {
    'POST /blacklists → 201': (r) => r.status === 201,
  });
  errorRate.add(!postOk);

  sleep(0.5);

  // GET /blacklists/<email> — consultar el email recién agregado
  const getRes = http.get(
    `${BASE_URL}/blacklists/${encodeURIComponent(email)}`,
    { headers: HEADERS, tags: { endpoint: 'get_blacklist' } }
  );

  getDuration.add(getRes.timings.duration);
  const getOk = check(getRes, {
    'GET /blacklists/<email> → 200':    (r) => r.status === 200,
    'GET responde exist=true':          (r) => {
      try { return JSON.parse(r.body).exist === true; }
      catch (_) { return false; }
    },
  });
  errorRate.add(!getOk);

  sleep(0.5);

  // GET /health — verificar que el servicio sigue respondiendo
  const healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, {
    'GET /health → 200': (r) => r.status === 200,
  });

  sleep(1);
}
