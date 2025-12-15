#!/usr/bin/env bash
# Jednoduché návrhy optimalizace – hledání anti-patternů
set -euo pipefail

PROJECT="${1:-}"
if [ -z "$PROJECT" ] || [ ! -d "$PROJECT" ]; then
  echo "Chyba: zadej cestu k projektu jako první argument" >&2
  exit 1
fi

echo "== Rychlá kontrola anti-patternů v $PROJECT =="
grep -Rni --exclude-dir=node_modules "forEach(" "$PROJECT" || true
grep -Rni --exclude-dir=node_modules "setTimeout(" "$PROJECT" || true
grep -Rni --exclude-dir=node_modules -E "fs\.readFileSync|fs\.writeFileSync" "$PROJECT" || true

if command -v prettier >/dev/null 2>&1; then
  echo "Prettier nalezen. Můžeš spustit: prettier --write <cesta>"
fi
if command -v eslint >/dev/null 2>&1; then
  echo "ESLint nalezen. Můžeš spustit: eslint --fix <cesta>"
fi
