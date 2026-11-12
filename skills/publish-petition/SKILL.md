---
name: publish-petition
description: Envía una petición ciudadana (.txt con el texto + imagen de portada) a la API del proyecto Laravel voz-ciudadana, que la crea como borrador ("draft") para revisión humana antes de publicarla.
metadata:
  short-description: Publica peticiones .txt+imagen como borrador vía API
---

# Voz Ciudadana — Publicador de Peticiones

Usa este skill cuando el usuario quiera enviar una petición ciudadana (archivo
`.txt` con el texto + una imagen de portada) al backend Laravel del proyecto
`voz-ciudadana` a través de su API REST.

## Importante: la API crea siempre un borrador

El endpoint de creación **siempre** deja la petición en `status="draft"`,
excluida de todos los listados públicos hasta que un admin humano la revisa y
la publica desde el panel. Esto es intencional — no hay forma de auto-publicar
saltándose la revisión, ni el skill debe intentar simularla. No prometas al
usuario que la petición queda visible en el sitio; deja claro que queda
pendiente de revisión.

## Credenciales — token, no email/password

El skill ya no hace login contra `POST /api/auth/token` en cada ejecución.
El operador genera **una sola vez**, en el servidor, un token de larga vida
con permisos acotados:

```
php artisan petitions:api-token <email> [--create-user]
```

Esto imprime un token tipo `1|xxxxx...` con abilities limitadas a
`["petitions:create","categories:read"]` — no puede tocar signatures ni nada
más. Si el token no tiene la ability requerida por el endpoint, la API
responde `403`.

Ese token se le pasa al script de una de estas formas (en este orden de
prioridad):

1. `--token <valor>`
2. variable de entorno `VOZ_CIUDADANA_API_TOKEN`
3. clave `token` (o `apiToken`) en el archivo `credentials` (por defecto en el
   cwd, o `--credentials <ruta>`)

```
# credentials
baseUrl=http://voz-ciudadana.test
token=1|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`baseUrl` también puede venir como `APP_URL` (mismo nombre que en el `.env`
del proyecto Laravel). Nunca imprimas el token en la salida ni lo copies a
otros archivos; si el usuario te pega el token en el chat, úsalo solo para
esta operación y no lo repitas en tu respuesta.

Los tokens antiguos generados por login (email/password) siguen funcionando
igual (ability `*` por default), pero para automatización usa siempre el
nuevo comando `petitions:api-token` — es más seguro por estar acotado.

## Formato del .txt de la petición

Visto en `peticion_ejemplo.txt` del proyecto:

- **Línea 1**: título de la petición → `title`.
- **Cuerpo narrativo** (desde la línea 2 hasta antes de `CARTA DEL ADHERENTE`)
  → `description`.
- **Desde `CARTA DEL ADHERENTE`** hasta el final (excluyendo la línea de
  correos) → `letter`.
- **Línea `Correos: correo1 correo2`** cerca del final: el primer correo es el
  destinatario de la carta → `email`; el segundo, si existe, → `email_cc`.

El script `scripts/petition_api.py parse` hace este parseo automáticamente.
Úsalo primero para revisar el resultado antes de enviar, especialmente si el
`.txt` no sigue exactamente ese formato (en ese caso, revisa a mano o pregunta
al usuario qué texto va en cada campo).

## Flujo

1. **Ver categorías disponibles** (necesitas el `category_id`):

   ```bash
   VOZ_CIUDADANA_API_TOKEN=... python3 ~/.claude/skills/publish-petition/scripts/petition_api.py categories --base-url http://voz-ciudadana.test
   ```

   Si el usuario no indica una categoría, muéstrale la lista y pregunta cuál
   usar — no inventes ni asumas un id por defecto sin confirmarlo.

2. **(Opcional) Revisar el parseo del .txt** antes de enviar:

   ```bash
   python3 ~/.claude/skills/publish-petition/scripts/petition_api.py parse peticion.txt
   ```

3. **Enviar la petición** (crea el borrador):

   ```bash
   VOZ_CIUDADANA_API_TOKEN=... python3 ~/.claude/skills/publish-petition/scripts/petition_api.py submit peticion.txt portada.jpg \
     --base-url http://voz-ciudadana.test \
     --category-id 3 \
     --goal 1000
   ```

   Flags relevantes:
   - `--category-id` (requerido): id resuelto en el paso 1.
   - `--goal` (opcional): meta de firmas — **el skill manda 1500 por defecto**
     (el default del backend es 500, pero el skill siempre lo sobreescribe con
     1500 salvo que se pase `--goal` explícito).
   - `--email-cc` (opcional): sobreescribe el segundo correo detectado en el `.txt`.
   - `--excerpt` (opcional): sobreescribe el excerpt autogenerado. Por defecto
     el script arma el excerpt tomando el primer párrafo de `description` y
     cortando en el primer punto; si esa primera oración es muy corta, incluye
     también la segunda. No dependas del autogenerado del backend — el skill
     ya manda su propio `excerpt` calculado así.
   - `--email-body` (opcional): texto crudo para el campo `email_body` (p.ej.
     el correo de agradecimiento post-firma, con su propio formato "Hola,
     {name}...", enlaces de campaña y botones de compartir). El skill **no
     redacta ni genera esta plantilla** — solo la reenvía tal cual si se le
     pasa. Si el usuario tiene ese texto (de otro sistema, plantilla fija,
     etc.), pégalo en este flag sin modificarlo.
   - `--whatsapp-petition` (opcional): texto crudo para el campo
     `whatsapp_petition` (mensaje para compartir por WhatsApp, formato tipo
     `wa.me/?text=` con `%0A` y el link de la campaña). Igual que
     `--email-body`, el skill **no genera este texto** — solo lo reenvía tal
     cual si el usuario lo trae ya armado.
   - `--dry-run`: imprime el request (multipart) sin llamarlo — úsalo para que
     el usuario revise el payload antes de enviarlo de verdad, sobre todo la
     primera vez.
   - `--token` / `--base-url` / `--credentials`: sobreescriben env
     var/credentials si hace falta.

   La imagen (`imagen`) debe ser un archivo de imagen válido de máx. 4MB; si es
   más grande, avisa al usuario antes de intentar el envío (el backend la
   rechazará con 422).

4. Tras un 201, informa al usuario que la petición quedó creada en estado
   `draft` y pendiente de revisión/publicación manual en el panel admin — no
   quedará visible en el sitio todavía.

## Errores comunes

- `HTTP 401` en `submit`/`categories`: token inválido o expirado.
- `HTTP 403`: el token no tiene la ability necesaria (`petitions:create` para
  `submit`, `categories:read` para `categories`). Pedir al operador que genere
  un token nuevo con `php artisan petitions:api-token <email>`.
- `HTTP 422`: revisar el detalle del error (se imprime completo) — típicamente
  `category_id` inexistente, imagen inválida/muy grande, o falta algún campo
  requerido (`email` sin detectar en el `.txt`, por ejemplo).

## Referencia

Lee [references/api-contract.md](references/api-contract.md) para el detalle
completo de los tres endpoints (auth, categorías, crear petición) si necesitas
construir una llamada manual fuera del script.
