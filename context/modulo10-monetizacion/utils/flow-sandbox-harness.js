#!/usr/bin/env node
/**
 * Harness de prueba del webhook recurrente de Walvy contra el SANDBOX de Flow.
 *
 * Hace, a mano, el trabajo del futuro productor (checkout → subscription/create)
 * para poder ejercitar el webhook YA, sin tener ese código todavía:
 *
 *   1. plans/create         — crea (o reutiliza) el plan en Flow
 *   2. customer/create      — crea el cliente con el EMAIL del usuario de tu DB
 *   3. customer/register     — devuelve la URL para ingresar la tarjeta de prueba
 *      → ⏸  tú abres la URL, ingresas la tarjeta 4051885600446623 / CVV 123, y vuelves
 *   4. customer/getRegisterStatus — confirma que la tarjeta quedó registrada
 *   5. subscription/create  — crea la suscripción → Flow cobra y llama al webhook
 *   6. siembra la fila local en `subscriptions` (lo que hará el productor real),
 *      para que el webhook pueda correlacionar el cobro con el usuario.
 *
 * Tras el paso 5, Flow hace POST a FLOW_CONFIRM_URL (tu ngrok) → tu backend corre
 * handleSubscriptionCharge. Mira los logs del backend: ver ../contexto/README.md.
 *
 * Uso:
 *   node flow-sandbox-harness.js               # usa EMAIL por defecto
 *   EMAIL=miguel.herize@kabeli.cl node flow-sandbox-harness.js
 *   PLAN=anual node flow-sandbox-harness.js    # plan anual (interval 4)
 *
 * Lee credenciales y DB desde back-walvy/.env. No instala nada (usa fetch/crypto
 * nativos de Node 18+ y el `pg` que ya está en back-walvy/node_modules).
 */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline');
const { createHmac } = require('node:crypto');

// --- localizar back-walvy/.env y node_modules/pg ---------------------------
const BACK = path.resolve(__dirname, '../../../../../back-walvy');
const ENV_PATH = path.join(BACK, '.env');
const { Client } = require(path.join(BACK, 'node_modules', 'pg'));

function loadEnv(file) {
  const out = {};
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) out[m[1]] = m[2].trim();
  }
  return out;
}

const env = loadEnv(ENV_PATH);
const API_URL = (env.FLOW_API_URL || 'https://sandbox.flow.cl/api').replace(/\/$/, '');
const API_KEY = env.FLOW_API_KEY;
const SECRET = env.FLOW_SECRET_KEY;
const RETURN_URL = env.FLOW_RETURN_URL || 'https://www.flow.cl';

// --- parámetros del test ----------------------------------------------------
const EMAIL = process.env.EMAIL || 'miguel.herize@kabeli.cl'; // debe existir en app_user
const PLAN_KIND = process.env.PLAN === 'anual' ? 'anual' : 'mensual';

const PLANS = {
  mensual: { planId: 'walvy-pro-mensual', name: 'Walvy Pro Mensual', amount: 6990, interval: 3, slug: 'pro_monthly' },
  anual: { planId: 'walvy-pro-anual', name: 'Walvy Pro Anual', amount: 59990, interval: 4, slug: 'pro_annual' },
};
const PLAN = PLANS[PLAN_KIND];

// payment  = pago único (Plan B): NO requiere contrato de cargo automático.
//            El token del pago no se guarda en nuestra DB → cae en la rama
//            recurrente del webhook. Valida todo salvo subscription/get.
// subscription = flujo recurrente real (customer/register + subscription/create).
//            Requiere que Flow habilite "cargo automático" en la cuenta.
const MODE = process.env.MODE === 'subscription' ? 'subscription' : 'payment';

// --- firma HMAC (idéntica a FlowService.sign) -------------------------------
function sign(params) {
  const toSign = Object.keys(params).sort().map((k) => k + params[k]).join('');
  return createHmac('sha256', SECRET).update(toSign).digest('hex');
}
function signed(params) {
  const full = { ...params, apiKey: API_KEY };
  return { ...full, s: sign(full) };
}

async function post(endpoint, params) {
  const res = await fetch(`${API_URL}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(signed(params)).toString(),
  });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!res.ok) throw new Error(`${endpoint} HTTP ${res.status}: ${text}`);
  return data;
}

async function get(endpoint, params) {
  const qs = new URLSearchParams(signed(params)).toString();
  const res = await fetch(`${API_URL}/${endpoint}?${qs}`);
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!res.ok) throw new Error(`${endpoint} HTTP ${res.status}: ${text}`);
  return data;
}

const ask = (q) =>
  new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(q, (a) => { rl.close(); resolve(a); });
  });

const flowDateToIso = (s) => (s ? new Date(String(s).replace(' ', 'T')).toISOString() : null);

async function main() {
  if (!API_KEY || !SECRET) throw new Error('Faltan FLOW_API_KEY / FLOW_SECRET_KEY en back-walvy/.env');

  console.log(`\n🌊 Flow sandbox harness`);
  console.log(`   API      : ${API_URL}`);
  console.log(`   Modo     : ${MODE}`);
  console.log(`   Plan     : ${PLAN.planId} (interval ${PLAN.interval}, $${PLAN.amount})`);
  console.log(`   Email    : ${EMAIL}`);
  console.log(`   Callback : ${env.FLOW_CONFIRM_URL || '⚠️  FLOW_CONFIRM_URL no seteado'}\n`);

  // 0) verificar que el usuario existe en la DB local antes de gastar llamadas a Flow
  const db = new Client({
    host: env.DB_HOST, port: Number(env.DB_PORT || 5432),
    user: env.DB_USERNAME, password: env.DB_PASSWORD, database: env.DB_NAME,
    ssl: env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });
  await db.connect();

  const userRes = await db.query('SELECT user_id FROM app_user WHERE email = $1 LIMIT 1', [EMAIL]);
  if (userRes.rowCount === 0) throw new Error(`No existe app_user con email ${EMAIL}. Usá EMAIL=<otro> o créalo.`);
  const userId = userRes.rows[0].user_id;

  const planRes = await db.query('SELECT id FROM subscription_plans WHERE slug = $1 LIMIT 1', [PLAN.slug]);
  if (planRes.rowCount === 0) throw new Error(`No existe subscription_plans con slug ${PLAN.slug}. ¿Booteaste el backend (seed)?`);
  const localPlanId = planRes.rows[0].id;
  console.log(`✔  Usuario local: ${userId}\n✔  Plan local   : ${localPlanId}\n`);

  if (MODE === 'payment') {
    await runPaymentMode(db, userId, localPlanId);
  } else {
    await runSubscriptionMode(db, userId, localPlanId);
  }

  await db.end();
}

/** Siembra/recrea la fila local en `subscriptions` que el webhook necesita para
 *  correlacionar el cobro con el usuario (lo que hará el productor real). */
async function seedLocalSubscription(db, userId, localPlanId, flowSubscriptionId, flowCustomerId) {
  const intervalDays = PLAN.interval === 4 ? 365 : 30;
  await db.query('DELETE FROM subscriptions WHERE user_id = $1', [userId]);
  await db.query(
    `INSERT INTO subscriptions
       (user_id, plan_id, flow_customer_id, flow_subscription_id, status,
        current_period_start, current_period_end, cancelled_at, created_at, updated_at)
     VALUES ($1,$2,$3,$4,$5,now(),now() + ($6 || ' days')::interval,NULL,now(),now())`,
    [userId, localPlanId, flowCustomerId ?? null, flowSubscriptionId ?? null, 'active', String(intervalDays)],
  );
}

function printExpected(userId, withSubscriptionGet) {
  console.log(`\n✅ Listo. Flow llama a tu webhook al confirmarse el pago.`);
  console.log(`   En los logs del backend esperás:`);
  console.log(`     [webhook] order found: null`);
  console.log(`     [webhook] subscription charge status 2 payer=${EMAIL}`);
  console.log(`     [webhook] recurring charge applied for user ${userId} → period end ...`);
  if (!withSubscriptionGet) {
    console.log(`   (modo payment: rama fallback, sin subscription/get — flow_subscription_id NULL)`);
  }
  console.log(`   En DB: 1 fila nueva en payment_orders (status=paid) ligada a la suscripción.\n`);
}

/**
 * MODO payment (Plan B, sin contrato de cargo automático).
 * Un pago único cuyo token NO guardamos cae en la rama recurrente del webhook.
 */
async function runPaymentMode(db, userId, localPlanId) {
  // 1) sembrar la fila local ANTES de pagar (evita la carrera con el callback).
  //    flow_subscription_id NULL → el webhook usa la rama de fallback.
  await seedLocalSubscription(db, userId, localPlanId, null, null);
  console.log(`✔  [1] fila local sembrada (flow_subscription_id NULL → rama fallback)`);

  // 2) pago único; urlConfirmation = nuestro webhook. commerceOrder único por corrida.
  const commerceOrder = `WALVY-TEST-${Date.now()}`;
  const pay = await post('payment/create', {
    commerceOrder, subject: `Prueba webhook Walvy — ${PLAN.name}`,
    currency: 'CLP', amount: PLAN.amount, email: EMAIL,
    urlConfirmation: env.FLOW_CONFIRM_URL, urlReturn: RETURN_URL,
  });
  console.log(`✔  [2] payment creado: flowOrder ${pay.flowOrder}`);
  console.log(`\n👉 [3] ABRÍ ESTA URL y pagá con la tarjeta de prueba:`);
  console.log(`      ${pay.url}?token=${pay.token}`);
  console.log(`      Tarjeta 4051885600446623 · CVV 123 (banco simulado: RUT 11111111-1 · clave 123)\n`);
  await ask('   ⏎ Presioná ENTER cuando hayas completado el pago... ');

  // 4) confirmación informativa (el webhook ya corrió cuando Flow llamó a urlConfirmation)
  const st = await get('payment/getStatus', { token: pay.token });
  console.log(`✔  [4] estado del pago en Flow: status=${st.status} (2=pagado) payer=${st.payer}`);
  printExpected(userId, false);
}

/**
 * MODO subscription (recurrente real). Requiere que Flow habilite "cargo
 * automático" en la cuenta sandbox; si no, customer/register devuelve 7001.
 */
async function runSubscriptionMode(db, userId, localPlanId) {
  // 1) plan en Flow (idempotente)
  try {
    await post('plans/create', {
      planId: PLAN.planId, name: PLAN.name, currency: 'CLP', amount: PLAN.amount,
      interval: PLAN.interval, trial_period_days: 0,
      urlCallback: env.FLOW_CONFIRM_URL, charges_retries_number: 3,
    });
    console.log(`✔  [1] plan creado en Flow: ${PLAN.planId}`);
  } catch {
    console.log(`ℹ  [1] plan ya existía: ${PLAN.planId}`);
  }

  // 2) cliente (externalId único por corrida; el webhook correlaciona por EMAIL)
  const externalId = `${userId}-${Date.now()}`;
  const customer = await post('customer/create', { name: 'Walvy Test', email: EMAIL, externalId });
  const customerId = customer.customerId;
  console.log(`✔  [2] customer: ${customerId}`);

  // 3) registro de tarjeta
  const reg = await post('customer/register', { customerId, url_return: RETURN_URL });
  console.log(`\n👉 [3] ABRÍ ESTA URL e ingresá la tarjeta de prueba:`);
  console.log(`      ${reg.url}?token=${reg.token}`);
  console.log(`      Tarjeta 4051885600446623 · CVV 123 (banco simulado: RUT 11111111-1 · clave 123)\n`);
  await ask('   ⏎ Presioná ENTER cuando hayas registrado la tarjeta... ');

  // 4) confirmar registro
  const regStatus = await get('customer/getRegisterStatus', { token: reg.token });
  if (String(regStatus.status) !== '1') {
    throw new Error(`Tarjeta NO registrada (status=${regStatus.status}). Reintentá el paso 3.`);
  }
  console.log(`✔  [4] tarjeta registrada: ${regStatus.creditCardType} ****${regStatus.last4CardDigits}`);

  // 5) sembrar fila local ANTES de subscription/create (evita la carrera)
  await seedLocalSubscription(db, userId, localPlanId, null, customerId);
  console.log(`✔  [5] fila local sembrada (flow_subscription_id pendiente)`);

  // 6) crear suscripción → Flow cobra y llama al webhook
  const sub = await post('subscription/create', { planId: PLAN.planId, customerId });
  console.log(`✔  [6] subscription: ${sub.subscriptionId} (status ${sub.status}, next_invoice ${sub.next_invoice_date})`);

  // 7) completar la fila con el id real y fechas autoritativas
  await db.query(
    `UPDATE subscriptions
       SET flow_subscription_id = $2,
           current_period_start = COALESCE($3, current_period_start),
           current_period_end   = COALESCE($4, current_period_end),
           updated_at = now()
     WHERE user_id = $1`,
    [userId, sub.subscriptionId, flowDateToIso(sub.period_start), flowDateToIso(sub.next_invoice_date || sub.period_end)],
  );
  console.log(`✔  [7] fila local completada (flow_subscription_id=${sub.subscriptionId})`);
  printExpected(userId, true);
}

main().catch((e) => { console.error(`\n❌ ${e.message}\n`); process.exit(1); });
