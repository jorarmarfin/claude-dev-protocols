# Catalogo de dependencias por categoria

Extraido de los proyectos reales del usuario (2025-2026). Usar como fuente
de verdad de versiones "conocidas buenas" al escribir el pubspec.yaml nuevo
— siempre verificar si hay una version mas nueva con `flutter pub outdated`
despues de armar el proyecto, pero partir de aqui evita adivinar.

## Base (SIEMPRE, en todo proyecto)

```yaml
flutter_riverpod: ^2.6.1
go_router: ^15.1.2
loading_animation_widget: ^1.3.0   # tipo elegido lo pregunta el skill
animate_do: ^4.2.0
url_launcher: ^6.3.2
in_app_update: ^4.2.5              # solo Android
package_info_plus: ^10.0.0
intl: ^0.20.2
cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.8
```

## Segun tipo de app

### Offline-first con base de datos relacional (varias tablas/relaciones)
```yaml
drift: ^2.34.0
drift_flutter: ^0.3.0
path_provider: ^2.1.5
path: ^1.9.1
dev_dependencies:
  drift_dev: (misma major que drift)
  build_runner: ^2.4.13
```

### Persistencia simple (listas/config, sin relaciones)
```yaml
shared_preferences: ^2.3.3
# o, si se prefiere NoSQL con cajas tipadas:
# hive: ^2.2.3
# hive_flutter: ^1.1.0
```

### App con backend/API remota
```yaml
http: ^1.6.0          # llamadas simples
# o dio: ^5.8.0+1     # si se necesitan interceptores/upload progress
```

### Backend gestionado (auth + DB + storage en la nube)
```yaml
supabase_flutter: ^2.17.1
flutter_dotenv: ^6.0.1   # variables .env (agregar .env a assets: y a .gitignore)
```

### Autenticacion local / bloqueo biometrico
```yaml
local_auth: ^2.3.0
flutter_secure_storage: ^9.2.4
```

### Notificaciones locales programadas (recordatorios, alarmas)
```yaml
flutter_local_notifications: ^18.0.1
timezone: ^0.9.4
```

### Reportes / PDF
```yaml
pdf: ^3.12.0
printing: ^5.13.4
```

### Compartir / exportar
```yaml
share_plus: ^10.1.4
```

### Graficos / dashboards
```yaml
fl_chart: ^0.69.2
```

### Imagenes remotas cacheadas
```yaml
cached_network_image: ^3.3.1
```

### Audio (radios, podcasts, musica en background)
```yaml
just_audio: ^0.9.42
just_audio_background: ^0.0.1-beta.14
audio_service: ^0.18.16
```

### Codigos QR
```yaml
qr_flutter: ^4.1.0
```

### Info de dispositivo / build
```yaml
device_info_plus: ^10.1.0
```

### Identificadores unicos
```yaml
uuid: ^4.5.1
```

### Tipografia de marca
```yaml
google_fonts: ^6.2.1
```

### Modelos inmutables (solo si hay >5 modelos con copyWith/equality complejos)
```yaml
freezed_annotation: ^3.1.0
json_annotation: ^4.12.0
dev_dependencies:
  freezed: (misma major)
  json_serializable: ^6.9.0
  build_runner: ^2.4.13
```

## Notas de version

- `loading_animation_widget` tiene decenas de tipos (`ThreeArchedCircle`,
  `StaggeredDotsWave`, `FourRotatingDots`, `WaveDots`, `DiscreteCircle`,
  `BouncingBall`, `TwistingDots`, `HexagonDots`, `StretchedDots`,
  `FallingDot`, `PulsingGrid`, `HalfTriangleDot`, `NewtonCradle`,
  `InkDrop`, `FlickrDots`, `Beat`, `Wave`, `HorizontalRotatingDots`...).
  El skill SIEMPRE pregunta cual usar antes de escribir el loading widget
  compartido — nunca asumir uno por defecto.
