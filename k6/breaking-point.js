/**
 * Prueba de punto de quiebre — Blacklist API
 *
 * Resultado del stress-test.js anterior (New Relic):
 *   - Respuesta promedio real: ~9ms (no los 300ms estimados)
 *   - Pico alcanzado: ~2,500 RPM con 40 VUs
 *   - Capacidad teórica del worker único: 60s / 0.009s ≈ 6,666 RPM
 *   - Se llegó solo al ~37% del límite — el servicio no se saturó
 *
 * Por qué no falló el anterior:
 *   Cada VU dormía 1.5 segundos entre ciclos (sleep 0.5 + sleep 1).
 *   Con 40 VUs y 1.5s de sleep, solo se generaban ~2,500 RPM efectivos.
 *   Para saturar 1 worker con 9ms de respuesta se necesitan:
 *     VUs_saturation ≈ 1 / 0.009s = 111 req/seg → ~100+ VUs sin sleep.
 *
 * Esta prueba elimina los sleeps y sube hasta 500 VUs para forzar
 * la cola del worker único y encontrar el verdadero punto de quiebre.
 *
 * Ejecutar:
 *   k6 run k6/breaking-point.js -e BASE_URL=http://<tu-url> -e TOKEN=<tu-token>
 */

import http from 'k6/http';
import { check } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ---------------------------------------------------------------------------
// Métricas personalizadas
// ---------------------------------------------------------------------------
const errorRate    = new Rate('error_rate');
const postDuration = new Trend('post_blacklist_duration', true);
const getDuration  = new Trend('get_blacklist_duration', true);

// ---------------------------------------------------------------------------
// Variables de entorno
// ---------------------------------------------------------------------------
const BASE_URL = __ENV.BASE_URL || 'http://35.175.187.95:5000';
const TOKEN    = __ENV.TOKEN    || 'my-static-secret-token';

const HEADERS = {
  Authorization: `Bearer ${TOKEN}`,
  'Content-Type': 'application/json',
};

// ---------------------------------------------------------------------------
// Fases — sin sleep, escalada agresiva
//
// Lógica de la escalada:
//   Con 9ms de respuesta y 1 worker:
//     ~111 req/seg = punto de saturación teórico
//     ~100 VUs sin sleep ≈ empieza la cola
//     ~200 VUs → cola de espera de ~1s por request
//     ~500 VUs → cola de ~4s, timeouts probables
//     ~1000 VUs → colapso o errores masivos de conexión
// ---------------------------------------------------------------------------
export const options = {
  stages: [
    // Fase 1 — Referencia limpia: pocos VUs para medir baseline sin sleep
    { duration: '1m', target: 10 },

    // Fase 2 — Pre-saturación: acercarse al límite teórico del worker
    { duration: '2m', target: 100 },

    // Fase 3 — Saturación: la cola del worker empieza a crecer
    { duration: '3m', target: 200 },

    // Fase 4 — Estrés severo: latencia debería dispararse
    { duration: '3m', target: 500 },

    // Fase 5 — Punto de quiebre: aquí esperamos errores y timeouts
    { duration: '3m', target: 1000 },

    // Fase 6 — Recuperación: ¿el servicio vuelve a responder correctamente?
    { duration: '3m', target: 0 },
  ],

  // Timeout por request: si el worker está muy ocupado, los requests esperan
  // en cola. 10s es un tiempo de espera máximo razonable antes de fallar.
  httpDebug: '',

  thresholds: {
    // Aceptamos hasta 20% de errores antes de fallar la prueba
    // (más permisivo porque estamos buscando el punto de quiebre)
    error_rate: ['rate<0.20'],

    // P95 debe estar por debajo de 5s incluso bajo estrés severo
    post_blacklist_duration: ['p(95)<5000'],

    // Tasa de fallos HTTP
    http_req_failed: ['rate<0.20'],
  },
};

// ---------------------------------------------------------------------------
// Función principal — sin sleep para máxima presión sobre el worker
// ---------------------------------------------------------------------------
export default function () {
  const vuId    = __VU;
  const iterNum = __ITER;

  // POST /blacklists — escribe en RDS, operación más pesada
  const email   = `break-vu${vuId}-iter${iterNum}@test.com`;
  const postRes = http.post(
    `${BASE_URL}/blacklists`,
    JSON.stringify({
      email:          email,
      app_uuid:       '550e8400-e29b-41d4-a716-446655440000',
      blocked_reason: `Breaking point VU=${vuId} iter=${iterNum}`,
    }),
    {
      headers: HEADERS,
      tags:    { endpoint: 'post_blacklist' },
      timeout: '10s',
    }
  );

  postDuration.add(postRes.timings.duration);
  const postOk = check(postRes, {
    'POST /blacklists → 201 o 400': (r) => r.status === 201 || r.status === 400,
  });
  errorRate.add(!postOk);

  // GET /blacklists/<email> — consulta en RDS
  const getRes = http.get(
    `${BASE_URL}/blacklists/${encodeURIComponent(email)}`,
    {
      headers: HEADERS,
      tags:    { endpoint: 'get_blacklist' },
      timeout: '10s',
    }
  );

  getDuration.add(getRes.timings.duration);
  const getOk = check(getRes, {
    'GET /blacklists/<email> → 200': (r) => r.status === 200,
  });
  errorRate.add(!getOk);

  // Sin sleep — presión máxima sobre el worker único
}
