# CLAUDE.md

Guia para Claude Code al trabajar en **{{APP_NAME}}**.

## Stack

- State management: Riverpod
- Navegacion: go_router
- Loading: loading_animation_widget ({{LOADING_TYPE}})
- Almacenamiento: {{STORAGE}}
- Theming: Material 3, ColorScheme.fromSeed a partir de AppColors.brand
  (derivado del logo en `assets/images/logo.png`)

## Comandos

```bash
flutter pub get
flutter run
flutter analyze
flutter test
./scripts/build_release.sh appbundle   # release con ofuscacion Dart
```

## Arquitectura (feature-first)

```
lib/
  app/                 MaterialApp/router bootstrap
  core/
    theme/             app_colors.dart, app_theme.dart
    router/             app_router.dart (go_router)
    constants/
    extensions/
    providers/          providers globales (riverpod)
    services/            wrappers de paquetes externos (storage, notifs, etc.)
    utils/
    widgets/             widgets reutilizables entre features
  features/<nombre>/
    data/                repositorios / fuentes de datos / modelos
    domain/              entidades y casos de uso (solo si la logica lo amerita)
    presentation/
      screens/
      widgets/
      providers/          estado especifico del feature (riverpod)
```

Reglas:
- Todo feature nuevo sigue esta misma estructura de 3 carpetas — no crear
  variantes (`services/`, `models/` sueltos, etc.) a nivel de feature.
- Riverpod solo donde el estado se comparte entre widgets o es asincrono.
  Estado local de formulario/animacion: `setState`.
- Nunca hardcodear colores — todo sale de `AppColors` / `Theme.of(context).colorScheme`.

## Release

- `applicationId`/`namespace`: {{APP_ID}}
- **Ofuscacion Dart obligatoria en release real**: usar
  `./scripts/build_release.sh` en vez de `flutter build` directo. Genera
  `symbols/<version>/` (gitignored) — respaldar esa carpeta fuera del repo,
  es la unica forma de leer stack traces de crashes de esa version.
