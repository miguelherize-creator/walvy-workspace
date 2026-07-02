const { createHmac } = require("node:crypto");

const API_KEY    = "TU_API_KEY_AQUI";
const SECRET_KEY = "TU_SECRET_KEY_AQUI";

function buildSignedCurl(endpoint, params) {
  const allParams = { apiKey: API_KEY, ...params };
  const keys = Object.keys(allParams).sort();
  const toSign = keys.map(k => k + allParams[k]).join("");
  const s = createHmac("sha256", SECRET_KEY).update(toSign).digest("hex");

  const body = [...keys.map(k => `${k}=${encodeURIComponent(allParams[k])}`), `s=${s}`].join("&");

  console.log(`\ncurl --location 'https://sandbox.flow.cl/api/${endpoint}' \\`);
  console.log(`  --header 'Content-Type: application/x-www-form-urlencoded' \\`);
  console.log(`  --data '${body}'`);
}

// Plan mensual
buildSignedCurl("plans/create", {
  planId: "walvy-pro-mensual",
  name: "Walvy Pro Mensual",
  amount: "6990",
  currency: "CLP",
  interval: "3",           // 3 = mensual
  trial_period_days: "0",
  urlCallback: "https://api.sonark.tech/subscriptions/webhook",
});

// Plan anual
buildSignedCurl("plans/create", {
  planId: "walvy-pro-anual",
  name: "Walvy Pro Anual",
  amount: "59990",
  currency: "CLP",
  interval: "4",           // 4 = anual
  trial_period_days: "0",
  urlCallback: "https://api.sonark.tech/subscriptions/webhook",
});
