# Fixtures reproducibles M01 · corte 05-sep-2026

RUT QA de la cuenta usada en la validación automática V41: 25.930.741-4.

| Archivo | Uso | Password | SHA-256 |
|---|---|---|---|
| `BANKC_BASE.pdf` | Base BANKCLONE-C no protegida | `—` | `3c9a0565b35b44f744ca15d7b5328ed3cb8af49c4df29f9eb91a69bbf0dedce1` |
| `BANKC_P1234.pdf` | Control negativo V41: fuerza fallback manual | `1234` | `eee968a484e295f284e00f224f2f6e41075b1c3318553506f1c521aa38c880dc` |
| `M01_FULL.pdf` | V41 variante automática RUT completo sin DV | `25930741` | `ae004bc472c22102cc72403cca8ade0c86ecb39ae0d835df44d75b33ecc64a1a` |
| `M01_LAST4.pdf` | V41 variante automática últimos 4 sin DV | `0741` | `d4965c4525f50a1a5b5976fa364c478d41881ab949ed4719811b497205c47477` |
| `M01_FIRST4.pdf` | V41 variante automática primeros 4 sin DV | `2593` | `8db4c42c632939885f06c062261aff81df787ec6d4b88ee05380c72f20d91290` |
| `V42_M3.pdf` | Intento V42 ~3 meses; resultado no evaluable por extracción | `—` | `e3ac9484407109f94e3b7f3f0f2f25908e95f127b51bc440e0fe098ad2a9f793` |

Nota: el estado de cuenta real usado como referencia interna no se incluye en el paquete externo por contener datos personales.