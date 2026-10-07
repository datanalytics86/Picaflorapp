#!/usr/bin/env bash
# Gates estáticos de la §11.2. Fallan el CI si hay coincidencias.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0

if grep -rnE "Color\(0x|fontSize:|BorderRadius\.circular\([0-9]" lib --include=*.dart | grep -v "lib/core/design_system/"; then
  echo "GATE hardcode: Color/fontSize/radio literal fuera del design system"
  fail=1
fi

if grep -rn "data/demo" lib --include=*.dart | grep -E "/presentation/|/screens/|/widgets/"; then
  echo "GATE demo: la UI no puede importar data/demo"
  fail=1
fi

if grep -rnE "print\(|debugPrint\(.*(lat|lon|email|token)" lib --include=*.dart; then
  echo "GATE pii: log con coordenada, email o token"
  fail=1
fi

if grep -n "setMockInitialValues" lib/main.dart; then
  echo "GATE prefs: API de test en el arranque"
  fail=1
fi

exit "$fail"
