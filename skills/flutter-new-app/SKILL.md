---
name: flutter-new-app
description: Crea la estructura base estandar de un nuevo proyecto Flutter del usuario — carpetas core/features, tema Material 3 derivado del logo, dependencias segun el tipo de app, iconos/splash, y script de ofuscacion para release. Usar cuando el usuario pida "nuevo proyecto flutter", "crea la estructura de mi app", "scaffold flutter", "flutter new app", o quiera empezar una app flutter nueva siguiendo su estandar personal. NO usar para dudas generales de Flutter/Dart en un proyecto existente (para eso esta el skill flutter-expert) ni para revisar codigo ya escrito — este skill es solo para el andamiaje inicial de un proyecto nuevo.
---

# Flutter New App — scaffolding estandar

Genera la base de un proyecto Flutter nuevo siguiendo el estandar personal
del usuario, derivado de sus apps reales (medi_casa, preparados_peru,
aulaconducta, etc.). El objetivo: que CUALQUIER proyecto nuevo tenga la
misma forma, para que el usuario (y Claude en sesiones futuras) nunca tenga
que adivinar donde esta algo.

Archivos de referencia en `templates/` (leerlos cuando toque generarlos,
no hace falta leerlos todos de entrada):
- `extract_colors.py` — deriva el color de marca del logo.
- `app_colors.dart.tpl`, `app_theme.dart.tpl` — tema Material 3.
- `build_release.sh.tpl` — build con ofuscacion Dart.
- `PROJECT_CLAUDE.md.tpl` — CLAUDE.md para el proyecto nuevo.
- `pubspec_deps.md` — catalogo de dependencias por categoria de app.
- `credits_screen.dart.tpl` — pantalla de creditos (ver Paso 8.5).

## Paso 0 — ubicar el logo y el nombre

El usuario siempre coloca el logo en la raiz de `/mnt/DATOS/flutter_apps/`
(o de la carpeta desde la que invoque el skill) antes de pedir el scaffold.
Busca ahi un archivo de imagen (`.png`/`.jpg`/`.svg`) que no pertenezca a
ningun proyecto existente — normalmente sera el unico archivo suelto en la
raiz. Si no lo encuentras, pregunta donde esta antes de seguir; no sigas
sin logo, porque el tema completo depende de el.

Pregunta (si no vino ya en el mensaje del usuario): nombre del proyecto
(usarlo para el nombre de carpeta en snake_case y como `name:` en
pubspec.yaml) y una idea de una linea de que hace la app.

## Paso 1 — preguntas de configuracion (AskUserQuestion)

Agrupa esto en 1-2 llamadas a AskUserQuestion (maximo 4 preguntas por
llamada). No asumas nada de esta lista sin preguntar:

1. **Tipo de app** (define almacenamiento/backend por defecto — ver
   `templates/pubspec_deps.md`):
   - Offline-first con base de datos local (varias entidades relacionadas) → drift
   - Con backend/API remota → http o dio
   - Backend gestionado (auth + sync en la nube) → supabase_flutter
   - Contenido estatico / informativa (sin persistencia compleja) → shared_preferences o nada

2. **Animacion de carga** (`loading_animation_widget` tiene muchos tipos,
   SIEMPRE preguntar, nunca asumir uno por defecto). Ofrece como opciones
   los mas usados por el usuario: `ThreeArchedCircle`, `StaggeredDotsWave`,
   `FourRotatingDots`, `WaveDots` — el usuario puede escribir otro nombre
   via "Other" si prefiere alguno distinto de la libreria.

3. **Necesita bloqueo/autenticacion local** (PIN o biometria via
   `local_auth` + `flutter_secure_storage`) — si/no.

4. **Necesita notificaciones locales programadas** (recordatorios/alarmas
   via `flutter_local_notifications`) — si/no.

5. **Navegacion inferior** (si la app tiene 3+ secciones principales de
   nivel raiz) — SIEMPRE preguntar, nunca asumir:
   - Notched bottom navigation bar (con FAB incrustado en la muesca)
   - Bottom app bar with docked FAB
   - Ninguna (sin bottom nav, ej. app de una sola pantalla o con drawer)

Si el tipo de app elegido en (1) ya implica claramente otras dependencias
(PDF, QR, audio, graficos, compartir, etc.), pregunta por esas tambien en
una segunda tanda solo si no es obvio; si el usuario ya las menciono en su
pedido original, no vuelvas a preguntar.

Riverpod y go_router van SIEMPRE, sin preguntar (son el estandar fijo del
usuario). google_fonts tambien va siempre, pero la fuente concreta se
puede preguntar en texto simple ("que fuente de Google Fonts?", default
razonable si no responde: `Inter` o una que combine con el logo).

## Paso 2 — crear el proyecto

```bash
flutter create --org com.<dominio_o_alias_del_usuario> --project-name <nombre_snake_case> <nombre_snake_case>
```

Si no sabes el org/dominio a usar, mira el `applicationId` de un proyecto
hermano existente en la misma carpeta padre (`grep applicationId
android/app/build.gradle.kts` de otro proyecto) y reutiliza el mismo
dominio para consistencia entre apps del usuario.

## Paso 3 — estructura de carpetas estandar

Crea exactamente esta forma dentro de `lib/` (es la que comparten
medi_casa y preparados_peru, las mas maduras del usuario):

```
lib/
  app/                    bootstrap: MaterialApp.router, providers raiz
  core/
    theme/                app_colors.dart, app_theme.dart
    router/                app_router.dart (go_router)
    constants/
    extensions/
    providers/             providers globales (riverpod)
    services/               wrappers de paquetes externos (storage, notifs...)
    utils/
    widgets/                widgets reutilizables entre features (botones, loaders...)
  features/
    <cada feature nueva>/
      data/                 repositorios / fuentes de datos / modelos
      domain/                (solo si la logica de negocio lo amerita)
      presentation/
        screens/
        widgets/
        providers/            estado especifico del feature (riverpod)
```

Regla fija: TODO feature nuevo replica exactamente `data/` +
`presentation/{screens,widgets,providers}` (+ `domain/` opcional). No
inventar variantes por feature — es lo que impide adivinar donde esta
cada cosa entre proyectos.

**Variantes observadas en apps maduras (validas, no forzar migracion):**
revisando preparados_peru en produccion (2026-08-29) salieron estas
desviaciones del arbol de arriba. Son validas para proyectos NUEVOS
tambien — no son errores a corregir en proyectos existentes:
- `core/services/` puede aparecer como carpetas propias con nombre
  especifico en vez de la carpeta generica — ej. `core/storage/`
  (wrapper de shared_preferences) y `core/notifications/` (wrapper de
  flutter_local_notifications) en vez de todo junto bajo `services/`.
  Preferible cuando cada wrapper es lo bastante grande/complejo como
  para merecer su propio nombre.
- `core/extensions/` puede vivir fusionado dentro de `core/utils/`
  (ej. `utils/date_extensions.dart`, `utils/context_extensions.dart`)
  en vez de carpeta separada, si son pocos archivos.
- `lib/app/` (bootstrap) puede no existir todavia si el proyecto crecio
  antes de que ese paso se agregara al skill — el bootstrap queda en
  `main.dart` directo. Sigue siendo el ideal para proyectos nuevos.
- Categorias core adicionales fuera del arbol base son normales cuando
  el dominio lo pide (ej. `core/backup/`, `core/update/` para
  exportar/restaurar datos o chequear versiones) — agregalas como
  hermanas de `theme/`, `router/`, etc., no las fuerces dentro de una
  categoria existente que no encaja.

No migres un proyecto existente a la letra del arbol solo por esta nota:
el costo (imports rotos en cascada, diff gigante, riesgo de regresion en
apps ya publicadas) no se justifica sin beneficio funcional. Usa esta
seccion para decidir donde poner cosas nuevas en ese proyecto, no para
reorganizar lo que ya funciona.

Crea tambien: `assets/images/`, `assets/fonts/` (si aplica), `scripts/`.

## Paso 4 — logo y tema derivado

1. Mueve el logo encontrado en el Paso 0 a `assets/images/logo.png`
   (convierte a PNG si venia en otro formato con `magick` o similar si
   esta disponible; si no, deja el formato original y ajusta el nombre).
2. Corre `python3 <ruta_skill>/templates/extract_colors.py assets/images/logo.png`
   dentro del proyecto para obtener `brand` (+ `light`/`dark`) en hex.
3. Genera `lib/core/theme/app_colors.dart` a partir de
   `templates/app_colors.dart.tpl`, reemplazando `{{BRAND_HEX_ARGB}}` etc.
   por `FF` + los 6 digitos hex sin `#` (formato ARGB de Flutter).
4. Genera `lib/core/theme/app_theme.dart` a partir de
   `templates/app_theme.dart.tpl`, reemplazando `{{GOOGLE_FONT}}` por el
   getter de `google_fonts` correspondiente a la fuente elegida (ej.
   `inter` para `GoogleFonts.interTextTheme`).
5. Declara `assets: - assets/images/` en pubspec.yaml.

No inventes una paleta manual color por color — el tema usa
`ColorScheme.fromSeed` a partir de `AppColors.brand`, asi Material 3
deriva todos los tonos de forma consistente en light y dark sin trabajo
manual. Si el usuario pide despues un ajuste puntual (ej. un acento
distinto para un boton especifico), agregalo como constante adicional en
`AppColors`, no reescribas el scheme completo a mano.

## Paso 5 — pubspec.yaml

Arma las dependencias combinando:
- La seccion "Base (SIEMPRE)" de `templates/pubspec_deps.md`.
- Las secciones que correspondan segun las respuestas del Paso 1.

Corre `flutter pub get` al terminar.

## Paso 6 — icono y splash

Agrega a `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.8

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#{{BRAND_HEX o blanco}}"
  adaptive_icon_foreground: "assets/images/logo.png"
  min_sdk_android: 21

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/images/logo.png
  color_dark: "#{{BRAND_DARK_HEX}}"
  image_dark: assets/images/logo.png
```

Corre `dart run flutter_launcher_icons` y
`dart run flutter_native_splash:create`.

## Paso 7 — ofuscacion

Copia `templates/build_release.sh.tpl` a `scripts/build_release.sh`, dale
permisos de ejecucion (`chmod +x`), y agrega `symbols/` al `.gitignore`
del proyecto.

## Paso 8 — CLAUDE.md del proyecto

Genera `CLAUDE.md` en la raiz del proyecto a partir de
`templates/PROJECT_CLAUDE.md.tpl`, con los placeholders resueltos segun
lo elegido en pasos anteriores. Esto es lo que le da continuidad a
sesiones futuras de Claude Code en ese proyecto especifico.

## Paso 8.5 — pantalla de creditos (SIEMPRE, sin preguntar)

Toda app nueva lleva una pantalla de Creditos, tomada del estandar
validado en aulaconducta (feature `settings`). No preguntar si el
usuario la quiere — es fija, como Riverpod y go_router.

1. Genera `lib/features/settings/screens/credits_screen.dart` a partir
   de `templates/credits_screen.dart.tpl`, reemplazando:
   - `{{APP_NAME}}` — nombre visible de la app.
   - `{{APP_PROPOSITO}}` — frase corta de a que ayuda la app (ej. "el
     bienestar en el aula"), para la tarjeta de agradecimiento.
   - `{{APP_PROPOSITO_CORTO}}` — descripcion de una linea para el texto
     de compartir (ej. "herramienta de analisis funcional de conducta
     para docentes").
   - `{{APP_FOOTER_FRASE}}` — frase final tipo "Hecho con amor para
     ...", coherente con el publico objetivo de la app.
   - `{{APPLICATION_ID}}` — el mismo `applicationId` usado en
     `android/app/build.gradle.kts` (para el link de Play Store).
2. Requiere el paquete `share_plus` (boton "Compartir") y
   `url_launcher` (link al sitio web) en pubspec.yaml — agregalos en
   el Paso 5 si no quedaron incluidos por otra razon.
3. Requiere una constante `appVersion` accesible (ej.
   `AppConstants.appVersion` en `shared/constants/app_constants.dart`
   o `core/constants/`) — usala para el chip de version al pie.
4. Registra la ruta en el router (`/credits`) y agrega un tile de
   entrada en la pantalla de Ajustes/Settings (icono
   `Icons.favorite_outline_rounded`, titulo "Creditos") que navegue con
   `context.push('/credits')`. Si el proyecto aun no tiene feature de
   Ajustes, crea `features/settings/` siguiendo la forma del Paso 3 y
   pon ahi tambien la pantalla de creditos.
5. El nombre "Luis Fernando Mayta Campos" / "luisitomayta.com" en la
   seccion Desarrollador son fijos del usuario — no los conviertas en
   placeholder.

## Paso 9 — resumen final

Al terminar, resume en pocas lineas: nombre del proyecto, dependencias
elegidas, tipo de loading animation, y que el logo/colores ya quedaron
aplicados. No hace falta listar cada archivo creado uno por uno.

---

## Como mejorar este skill con el tiempo

Este skill se alimenta de los proyectos reales del usuario. Cada vez que
termines un scaffold o trabajes en un proyecto ya creado con este skill y
notes algo que deberia ser el estandar (un paquete nuevo que el usuario
adopto, un cambio de estructura, una preferencia repetida), actualiza este
archivo o los templates directamente — no dejes el conocimiento solo en la
conversacion. Concretamente:

- Si el usuario agrega un paquete a 2+ proyectos nuevos que no esta en
  `templates/pubspec_deps.md`, agregalo ahi en la categoria correspondiente.
- Si el usuario corrige la estructura de carpetas propuesta, actualiza el
  Paso 3 de este archivo para que sea el nuevo default.
- Si cambia de idea sobre Riverpod/go_router como fijos, actualizalo aqui
  explicitamente (hoy son innegociables por decision expresa del usuario).
- Para cambios grandes de flujo (nuevas preguntas, pasos reordenados), usa
  el skill `skill-creator` para iterar y, si aplica, correr evals.
- Manten `README.md` (en esta misma carpeta) apuntando siempre a este
  archivo como fuente de verdad — el README es solo la puerta de entrada,
  no dupliques contenido ahi.
