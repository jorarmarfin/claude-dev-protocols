---
name: laravel-composer-kit
description: Instala y configura el set de paquetes composer que el usuario usa siempre en proyectos Laravel + Filament — PDF (elibyy/tcpdf-laravel), Excel (maatwebsite/excel), log monitor (luiscamp/laravel-log-monitor), Filament + roles (filament/filament, bezhansalleh/filament-shield), ubigeo Perú (luiscamp/laravel-peru-ubigeo), activity log (rmsramos/activitylog) y facturación electrónica (greenter/greenter). Usar cuando el usuario pida "instala mi kit de paquetes", "agrega Filament a este proyecto", "necesito exportar a Excel/PDF", "agrega el log monitor", "agrega ubigeo", o esté armando un Laravel nuevo y quiera el set estándar. Basado en el composer.json real de SisLibun.
---

# Skill: Laravel Composer Kit

## Propósito

Instalar y dejar configurado, uno o varios a la vez, el set de paquetes
composer que el usuario repite en sus proyectos Laravel + Filament, con
los mismos pasos de post-instalación que usa en producción (SisLibun),
para no tener que recordar comandos ni configuración cada vez.

Sigue después de [[project-scaffold]] (Laravel base ya instalado) y antes
de [[phase-implementation-checklist]] (una vez el kit está listo, se
implementan features).

## Triggers

- "instala mi kit de paquetes" / "instala los paquetes de siempre"
- "agrega Filament a este proyecto"
- "necesito exportar a Excel" / "necesito generar PDF"
- "agrega el log monitor" / "agrega ubigeo"
- Al iniciar un Laravel nuevo del usuario y preguntarle qué necesita

**Facturación electrónica (greenter) NO es parte del kit estándar** — solo
se instala si el usuario lo pide explícitamente por nombre ("quiero
facturación electrónica", "agrega greenter", "el negocio factura a
SUNAT"). No lo ofrezcas en el checklist por defecto, no todos los
proyectos facturan.

## Comportamiento

### 0. Preguntar qué paquetes del kit necesita esta vez

No instales el kit completo por defecto — pregunta cuáles de estos aplican
a este proyecto (usa AskUserQuestion, multiSelect). Este es el set
estándar, greenter queda fuera de esta lista a propósito:

- **Filament** (panel admin) — casi siempre sí si hay backoffice
- **Filament Shield** (roles/permisos) — solo si Filament está incluido
- **Excel** (import/export)
- **PDF**
- **Log monitor**
- **Ubigeo Perú** — solo si el proyecto es para Perú
- **Activity log** (auditoría de cambios) — normalmente junto con Filament

Verifica primero `composer.json` del proyecto para no reinstalar lo que
ya está.

### 1. Paquetes y comandos de instalación

#### Filament (panel admin)

```bash
composer require filament/filament
php artisan filament:install --panels
```
Crea `app/Providers/Filament/AdminPanelProvider.php`. Configuración base
que usa el usuario ahí (replicar si pide "como en SisLibun"):
- `->topNavigation()`
- `->profile(EditProfile::class, isSimple: true)` con página custom de perfil
- Colores explícitos por semántica: `danger` Rose, `gray` Gray, `info`
  Blue, `primary` Indigo, `success` Emerald, `warning` Orange
- `->brandLogo(asset('images/logo.png'))` + `->favicon(...)`
- `->navigationGroups([...])` explícitos (no dejar que Filament agrupe solo)

#### Filament Shield (roles y permisos)

Requiere Filament ya instalado.
```bash
composer require bezhansalleh/filament-shield
php artisan shield:install --panel=admin
```
Genera `config/filament-shield.php`. Registrar el plugin en el
`AdminPanelProvider`:
```php
use BezhanSalleh\FilamentShield\FilamentShieldPlugin;
// dentro de ->plugins([ FilamentShieldPlugin::make(), ... ])
```
Después de crear cada Resource nueva: `php artisan shield:generate
--resource=NombreResource` (o `--all`) para generar sus permisos.

#### Excel (maatwebsite/excel)

```bash
composer require maatwebsite/excel
```
No necesita config publicada por defecto (SisLibun lo usa con config por
defecto). Para import/export: crear clases en `app/Exports/` /
`app/Imports/` implementando `FromCollection`/`WithHeadings` o
`ToModel`/`WithHeadingRow` según el caso. Si el proyecto necesita
personalizar límites de memoria/chunking, publicar config:
```bash
php artisan vendor:publish --provider="Maatwebsite\Excel\ExcelServiceProvider" --tag=config
```

#### PDF (elibyy/tcpdf-laravel)

```bash
composer require elibyy/tcpdf-laravel
```
Uso vía facade `PDF::` (alias registrado por el paquete). Generar vistas
Blade específicas para PDF en `resources/views/pdf/` y renderizar con
`PDF::loadView('pdf.nombre', $data)->stream()` o `->download('archivo.pdf')`.

#### Log Monitor (luiscamp/laravel-log-monitor)

```bash
composer require luiscamp/laravel-log-monitor
php artisan vendor:publish --tag=log-monitor-config
```
Genera `config/log-monitor.php`. Revisar ahí la ruta donde queda
disponible el visor de logs y restringir acceso (middleware de
auth/admin) antes de exponerlo en producción.

#### Ubigeo Perú (luiscamp/laravel-peru-ubigeo)

```bash
composer require luiscamp/laravel-peru-ubigeo
php artisan vendor:publish --tag=ubigeo-migrations   # si el paquete lo requiere
php artisan migrate
```
Revisar el README del paquete instalado para el nombre exacto del tag de
publish (puede variar entre versiones) — no asumir el flag de migrate sin
confirmarlo contra `vendor/luiscamp/laravel-peru-ubigeo`.

#### Activity Log (rmsramos/activitylog)

```bash
composer require rmsramos/activitylog
php artisan vendor:publish --tag="filament-activitylog-config"
php artisan migrate
```
Genera `config/activitylog.php` y `config/filament-activitylog.php`. Si
hay Filament instalado, registrar el plugin:
```php
use Rmsramos\Activitylog\ActivitylogPlugin;
// dentro de ->plugins([ ActivitylogPlugin::make(), ... ])
```
Para que un modelo registre auditoría: usar el trait `LogsActivity` del
paquete subyacente (spatie/laravel-activitylog) en el modelo.

#### Greenter (facturación electrónica SUNAT — Perú)

```bash
composer require greenter/greenter
php artisan vendor:publish --tag=greenter-config
```
Genera `config/greenter.php`. Requiere credenciales SOL/certificado
digital del cliente — nunca commitear certificados ni credenciales; van
en `.env`, referenciadas desde `config/greenter.php`.

### 2. Después de instalar cualquier paquete

- Corre `composer install`/`update` y confirma que no hay conflictos de
  versión antes de continuar
- Si el paquete publica config, revisa el archivo generado y ajusta
  según el proyecto (no dejar los defaults sin revisar)
- Si el paquete requiere migración, revisa el archivo generado en
  `database/migrations/` antes de `php artisan migrate`
- Si es un plugin de Filament, confirma que quedó registrado en
  `->plugins([...])` del panel provider correspondiente
- Sugiere agregar `require`/`require-dev` ordenado (SisLibun usa
  `"sort-packages": true` en `composer.json` — mantenlo así)

## Instrucciones especiales

- **No instales todo el kit de una** salvo que el usuario lo pida
  explícitamente — pregunta cuáles aplican a este proyecto
- **Ubigeo y Greenter son específicos de Perú** — no los sugieras en
  proyectos que no sean para ese mercado
- **Filament Shield y Activity Log dependen de Filament** — verifica que
  esté instalado antes de instalarlos
- **Nunca commitear credenciales/certificados de Greenter** — siempre
  vía `.env`
- Si el usuario dice "como en SisLibun", replica exactamente los
  nombres de paquete y versiones (`^` según lo que traiga el
  `composer.json` de referencia) en vez de instalar `latest` a ciegas,
  para mantener consistencia entre proyectos
- Verifica versión de PHP/Laravel del proyecto destino antes de
  instalar — SisLibun corre PHP ^8.3 + Laravel ^13 + Filament ^5.7; un
  proyecto en versiones más viejas puede necesitar versiones distintas
  de estos paquetes
