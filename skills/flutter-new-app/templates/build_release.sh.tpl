#!/usr/bin/env bash
# Build de produccion con ofuscacion de codigo Dart (--obfuscate).
#
# La ofuscacion de Dart es independiente del ProGuard/R8 de Android
# (android/app/proguard-rules.pro, que ya ofusca/reduce el bytecode Java/
# Kotlin en el build "release"): --obfuscate renombra simbolos Dart
# (nombres de clases, metodos) en el binario compilado a AOT, dificultando
# el reverse engineering del codigo Flutter.
#
# --split-debug-info guarda el mapeo simbolo-ofuscado -> simbolo real. Sin
# ese mapeo, un stack trace de un crash en produccion es ilegible. Hay que
# conservar la carpeta symbols/<version> (fuera de git, respaldarla aparte)
# para poder des-ofuscar crashes reportados por Play Console o Crashlytics.
#
# Uso:
#   ./scripts/build_release.sh appbundle   # .aab para Play Store (default)
#   ./scripts/build_release.sh apk         # .apk para pruebas/sideload

set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-appbundle}"
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
SYMBOLS_DIR="symbols/${VERSION}"

mkdir -p "$SYMBOLS_DIR"

echo "Compilando ${TARGET} v${VERSION} con ofuscacion..."
flutter build "$TARGET" --release \
  --obfuscate \
  --split-debug-info="$SYMBOLS_DIR"

echo
echo "Build listo. Simbolos de depuracion guardados en: ${SYMBOLS_DIR}"
echo "  Respalda esta carpeta fuera del repo (no se sube a git) - es la"
echo "  unica forma de des-ofuscar los stack traces de esta version."
