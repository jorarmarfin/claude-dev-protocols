# tests/ — {{PROJECT_NAME}}

Suite de pruebas end-to-end (Playwright recomendado, pero cualquier runner sirve).
Convención de reportes, para poder ordenarlos cronológicamente y saber a qué corrida
corresponde cada uno sin abrirlo:

```
reports/{{fecha}}_{{hora}}__{{contexto}}__{{modo}}__{{veredicto}}.pdf
```

- `{{fecha}}_{{hora}}`: `AAAA-MM-DD_HHMM`
- `{{contexto}}`: qué se probó (`linea-base`, nombre-del-plugin-y-versión, etc.)
- `{{modo}}`: `completo` (suite entera) o `prioritario` (solo casos críticos)
- `{{veredicto}}`: `APROBADO` o `RECHAZADO`

Ejemplo: `2026-09-07_1430__actualizacion-core-6-8__prioritario__APROBADO.pdf`

## Setup

```bash
cd tests
npm install
npx playwright install --with-deps
```

## Correr

```bash
npm test
```

Ajustar `playwright.config.js` con la URL base (`{{LOCAL_SCHEME}}://{{LOCAL_DOMAIN}}`)
y las credenciales de `.env`.
