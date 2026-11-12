# API de peticiones — voz-ciudadana

Base: `{APP_URL}` del `.env` del proyecto Laravel (ej. `http://voz-ciudadana.test`).

## 0. Token de API (recomendado para automatización)

El skill NO hace login por email/password en cada ejecución. El token se
genera una sola vez, en el servidor, con:

```
php artisan petitions:api-token <email> [--create-user]
```

Esto imprime un token Sanctum tipo `1|xxxxx...` con abilities acotadas a
`["petitions:create","categories:read"]`. Guardar ese valor (env var
`VOZ_CIUDADANA_API_TOKEN`, `--token`, o `token=` en `credentials`) y usarlo
directamente como `Authorization: Bearer <token>` en los endpoints 2 y 3 — no
hace falta pasar por `/api/auth/token`.

Si el token no tiene la ability requerida por el endpoint, la API responde
`403` (verificado: un token con solo `categories:read` recibe 403 al intentar
`POST /api/petitions`).

Los tokens antiguos emitidos por el flujo de login (`POST /api/auth/token`,
ver abajo) siguen funcionando igual — tienen ability `*` por default — pero
no son la vía recomendada para el skill.

## 1. Auth por login (legado, sigue funcionando)

```
POST /api/auth/token
Content-Type: application/json
{ "email": "...", "password": "..." }
```
- 200 → `{ "token": "...", "message": "..." }`
- 401 → credenciales inválidas

Usar el token en todas las llamadas siguientes: `Authorization: Bearer <token>`, `Accept: application/json`.

## 2. Listar categorías

```
GET /api/categories
Authorization: Bearer <token>
```
→ 200 `{ "success": true, "items": [ {"id":1,"name":"Salud","slug":"salud"}, ... ] }`
→ 403 si el token no tiene ability `categories:read`

Usar esto para resolver `category_id`. No inventar ids.

## 3. Crear petición (borrador)

```
POST /api/petitions
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

Campos:

| campo | tipo | requerido | notas |
|---|---|---|---|
| title | string | sí | |
| description | string | sí | cuerpo/historia |
| letter | string | sí | carta dirigida al destinatario |
| email | string | sí | correo del destinatario de la carta |
| email_cc | string | no | |
| email_body | string | no | si se omite, el backend usa `letter`. En la práctica puede llevar la plantilla de agradecimiento post-firma ("Hola, {name}...", enlaces de campaña, botones para compartir) — el skill solo reenvía este texto tal cual si se lo pasan (`--email-body`), no lo redacta |
| category_id | integer | sí | debe existir (ver endpoint 2) |
| goal | integer | no | default backend 500 — **el skill siempre manda 1500** salvo que se pase `--goal` explícito |
| excerpt | string | no | si se omite, el backend lo autogenera desde `description` (`Str::limit(strip_tags(description), 150)`) — pero **el skill siempre manda su propio excerpt**: primer párrafo de `description` cortado en el primer punto (o hasta el segundo si el primero deja muy poco texto) |
| whatsapp_petition | string | no | texto para compartir por WhatsApp (formato tipo `wa.me/?text=`, con `%0A` y el link de la campaña). Nullable, puro passthrough — el skill no lo genera, solo lo reenvía si se lo dan (`--whatsapp-petition`) |
| imagen | file | sí | imagen válida, máx 4MB |

- 201 → `{ "success": true, "item": { ...status: "draft"... } }`
- 403 → token sin ability `petitions:create`
- 422 → `{ "success": false, "errors": {...} }`

## Comportamiento importante

La petición se crea **siempre** con `status="draft"` y queda excluida de todos los
listados públicos (`GET /api/getpetitions`, `/api/getpetitionlast`,
`/api/getpetition/{id}`, widgets del sitio) hasta que un admin humano la revise
y cambie el estado a `open` desde el panel. No existe ni se debe intentar un
mecanismo para saltarse esa revisión.
