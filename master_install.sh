#!/usr/bin/env bash
# Acode Dev Master Installer – automatická inicializace struktury a doplnění souborů
# Version: 1.0
# Autor: Starko / Fatalerorr69
# Popis: Vytvoří kompletní strukturu Acode_Dev_Master v $HOME/.acode_dev_master a doplní základní soubory

set -euo pipefail
IFS=$'\n\t'

WORKDIR="${HOME}/.acode_dev_master"
PLUGINS_DIR="${WORKDIR}/plugins"
CONFIGS_DIR="${WORKDIR}/configs"
DOCS_DIR="${WORKDIR}/docs"
CORE_DIR="${WORKDIR}/core"
DASHBOARD_DIR="${WORKDIR}/dashboard"
DASH_TEMPLATES_DIR="${DASHBOARD_DIR}/templates"
REPORTS_DIR="${WORKDIR}/reports"
LOGS_DIR="${WORKDIR}/logs"
ZIP_SCRIPT="${WORKDIR}/create_zip.sh"
README_FILE="${WORKDIR}/README.md"
LICENSE_FILE="${WORKDIR}/LICENSE"
GITIGNORE_FILE="${WORKDIR}/.gitignore"
INSTALL_LOG="${WORKDIR}/install.log"

# ---------- LOGGING ----------
log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$INSTALL_LOG"
}

err() {
  printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$INSTALL_LOG" >&2
}

trap 'err "Selhání na řádku $LINENO"; exit 1' ERR

# ---------- HELPERS ----------
ensure_dir() {
  local d="$1"
  if [ ! -d "$d" ]; then
    mkdir -p "$d"
    log "Vytvořeno: $d"
  else
    log "Existuje: $d"
  fi
}

backup_if_exists() {
  local f="$1"
  if [ -e "$f" ]; then
    local ts
    ts="$(date +%F_%H-%M-%S)"
    local bak="${f}.bak.${ts}"
    mv "$f" "$bak"
    log "Záloha: $f -> $bak"
  fi
}

write_file_if_missing() {
  local path="$1"
  local content="$2"
  if [ -e "$path" ]; then
    log "Soubor již existuje, přeskočeno: $path"
  else
    printf '%s\n' "$content" > "$path"
    log "Vytvořen soubor: $path"
  fi
}

write_file_force() {
  local path="$1"
  local content="$2"
  backup_if_exists "$path"
  printf '%s\n' "$content" > "$path"
  log "Zapsán soubor: $path (přepsáno)"
}

make_executable() {
  local f="$1"
  if [ -f "$f" ]; then
    chmod +x "$f"
    log "Nastaven spustitelný bit: $f"
  fi
}

# ---------- VYTVOŘENÍ STRUKTURY ----------
log "Inicializuji adresářovou strukturu v $WORKDIR"
ensure_dir "$WORKDIR"
ensure_dir "$PLUGINS_DIR"
ensure_dir "$CONFIGS_DIR"
ensure_dir "$DOCS_DIR"
ensure_dir "$CORE_DIR"
ensure_dir "$DASHBOARD_DIR"
ensure_dir "$DASH_TEMPLATES_DIR"
ensure_dir "$REPORTS_DIR"
ensure_dir "$LOGS_DIR"

# ---------- ZÁKLADNÍ SOUBORY ----------
readme_content="# Acode Dev Master Installer

**Acode Dev Master Installer** je modulární nástroj pro instalaci a správu mobilního i desktopového vývojového prostředí.
Tento balíček vytvoří základní strukturu, core skripty, pluginy a jednoduchý dashboard.

## Rychlý start
1. Spusť tento skript:
   \`\`\`bash
   chmod +x master_install.sh
   ./master_install.sh
   \`\`\`
2. Po vytvoření struktury spusť instalátor znovu nebo použij menu.

## Struktura
- \`configs/\` centrální konfigurace
- \`core/\` základní skripty (analyze, improve, ai-review)
- \`plugins/\` pluginy
- \`dashboard/\` jednoduchý Flask dashboard
- \`reports/\` a \`logs/\` pro výstupy

## Licence
Projekt je licencován pod MIT. Viz soubor LICENSE.
"
write_file_if_missing "$README_FILE" "$readme_content"

license_content="MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"
write_file_if_missing "$LICENSE_FILE" "$license_content"

gitignore_content="/logs/
/reports/
/*.zip
*.pyc
__pycache__/
.env
"
write_file_if_missing "$GITIGNORE_FILE" "$gitignore_content"

config_json='{
  "project_dir": "$HOME/projects",
  "ai_engine": "auto",
  "default_model": "codellama",
  "report_dir": "$HOME/.acode_dev_master/reports",
  "plugins_dir": "$HOME/.acode_dev_master/plugins",
  "sandboxing": {
    "preferred": ["firejail", "docker"],
    "enabled": true
  },
  "non_interactive_defaults": {
    "assume_yes": false
  }
}'
write_file_if_missing "${CONFIGS_DIR}/acode_settings.json" "$config_json"

install_md="# Instalace Acode Dev Master Installer

Tento dokument popisuje kroky pro instalaci a základní konfiguraci.

Rychlá instalace:
\`\`\`bash
git clone https://github.com/Fatalerorr69/Skripty.git \"\$HOME/.acode_dev_master/Skripty\"
git clone https://github.com/Fatalerorr69/Acode_dev_toolkit.git \"\$HOME/.acode_dev_master/Acode_dev_toolkit\"
chmod +x master_install.sh
./master_install.sh
\`\`\`
"
write_file_if_missing "${DOCS_DIR}/INSTALL.md" "$install_md"

# ---------- CORE SCRIPTS ----------
analyze_sh='#!/usr/bin/env bash
# Statická analýza projektu
set -euo pipefail
PROJECT="${1:-}"
if [ -z "$PROJECT" ] || [ ! -d "$PROJECT" ]; then
  echo "Chyba: zadej cestu k projektu jako první argument" >&2
  exit 1
fi
REPORT_DIR="${ACODE_REPORT_DIR:-$HOME/.acode_dev_master/reports}"
mkdir -p "$REPORT_DIR"
TS="$(date +%F_%H-%M-%S)"
TXT_REPORT="$REPORT_DIR/analysis_${TS}.txt"
JSON_REPORT="$REPORT_DIR/analysis_${TS}.json"

echo "== ANALÝZA PROJEKTU: $PROJECT ==" | tee "$TXT_REPORT"
du -sh "$PROJECT" | tee -a "$TXT_REPORT"
echo "Počet souborů:" | tee -a "$TXT_REPORT"
find "$PROJECT" -type f | wc -l | tee -a "$TXT_REPORT"
echo "TODO/FIXME/BUG/HACK:" | tee -a "$TXT_REPORT"
grep -RniE "TODO|FIXME|BUG|HACK" "$PROJECT" || true

cat > "$JSON_REPORT" <<EOF
{
  \"project\": \"$PROJECT\",
  \"timestamp\": \"$TS\",
  \"size\": \"$(du -sh "$PROJECT" | cut -f1)\",
  \"file_count\": $(find "$PROJECT" -type f | wc -l)
}
EOF

echo "Report uložen: $TXT_REPORT a $JSON_REPORT"
'
write_file_if_missing "${CORE_DIR}/analyze.sh" "$analyze_sh"
make_executable "${CORE_DIR}/analyze.sh"

improve_sh='#!/usr/bin/env bash
# Jednoduché návrhy optimalizace
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
'
write_file_if_missing "${CORE_DIR}/improve.sh" "$improve_sh"
make_executable "${CORE_DIR}/improve.sh"

ai_review_sh='#!/usr/bin/env bash
# AI review: bezpečné volání AI enginu, výstup jako návrh do .ai.suggest
set -euo pipefail
FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Chyba: zadej cestu k souboru jako první argument" >&2
  exit 1
fi
MAX_BYTES=200000
SIZE=$(wc -c < "$FILE")
if [ "$SIZE" -gt "$MAX_BYTES" ]; then
  echo "Soubor je příliš velký pro AI review (>$MAX_BYTES bajtů)" >&2
  exit 1
fi

OUT="${FILE}.ai.suggest"
echo "Generuji návrh AI (neaplikuje se automaticky)."

if command -v ollama >/dev/null 2>&1; then
  ollama run codellama \"Analyze and propose a patch for the following file:\" < \"$FILE\" > \"$OUT\" || true
elif command -v openai >/dev/null 2>&1; then
  openai api completions.create -m text-davinci-003 -i \"$FILE\" > \"$OUT\" || true
elif python3 -c \"import transformers\" >/dev/null 2>&1; then
  python3 - <<PY > \"$OUT\"
from transformers import pipeline
with open(\"$FILE\",\"r\",encoding=\"utf-8\") as f:
    code=f.read()
print(\"AI návrh: zkontroluj a navrhni refaktor. (Ukázka)\")
PY
else
  echo "Žádný AI engine dostupný. Nastav OLLAMA nebo OPENAI CLI nebo nainstaluj transformers." >&2
  exit 1
fi

echo "AI návrh uložen do $OUT"
'
write_file_if_missing "${CORE_DIR}/ai-review.sh" "$ai_review_sh"
make_executable "${CORE_DIR}/ai-review.sh"

# ---------- PLUGINY: vytvoření ukázkových pluginů ----------
create_plugin() {
  local name="$1"
  local content="$2"
  local dir="${PLUGINS_DIR}/${name}"
  ensure_dir "$dir"
  local file="${dir}/plugin.sh"
  write_file_force "$file" "$content"
  make_executable "$file"
}

audit_plugin='#!/usr/bin/env bash
acode_plugin_meta() {
  cat <<EOF
{
  "name": "audit_plugin",
  "version": "0.2.0",
  "author": "Starko",
  "description": "Kontroluje pluginy a package.json"
}
EOF
}
acode_plugin_init() {
  WORKDIR="$1"
  mkdir -p "$WORKDIR/plugins/audit/data"
  echo "audit_plugin: inicializováno"
}
acode_plugin_run() {
  PLUGIN_DIR="${1:-$HOME/.acode_dev_master/plugins}"
  echo "audit_plugin: kontroluji pluginy v $PLUGIN_DIR"
  for p in "$PLUGIN_DIR"/*; do
    [ -d "$p" ] || continue
    echo "PLUGIN: $(basename "$p")"
    if [ -f "$p/package.json" ]; then
      command -v jq >/dev/null 2>&1 && jq '.name,.version,.scripts' "$p/package.json" || echo "Nelze číst package.json"
      grep -niE "\"postinstall\"|\"install\"" "$p/package.json" || true
    fi
  done
}
'
create_plugin "audit" "$audit_plugin"

lint_plugin='#!/usr/bin/env bash
acode_plugin_meta() {
  cat <<EOF
{
  "name": "lint_plugin",
  "version": "0.1.0",
  "author": "Starko",
  "description": "Spouští ESLint nebo flake8 a ukládá reporty"
}
EOF
}
acode_plugin_init() {
  WORKDIR="$1"
  mkdir -p "$WORKDIR/plugins/lint/reports"
  echo "lint_plugin: inicializováno"
}
acode_plugin_run() {
  TARGET="${1:-$HOME/projects}"
  REPORT_DIR="${ACODE_REPORT_DIR:-$HOME/.acode_dev_master/reports}"
  mkdir -p "$REPORT_DIR"
  if command -v eslint >/dev/null 2>&1; then
    eslint "$TARGET" -f json -o "$REPORT_DIR/eslint_report.json" || true
    echo "ESLint report: $REPORT_DIR/eslint_report.json"
  fi
  if command -v flake8 >/dev/null 2>&1; then
    flake8 "$TARGET" --format=json > "$REPORT_DIR/flake8_report.json" || true
    echo "flake8 report: $REPORT_DIR/flake8_report.json"
  fi
}
'
create_plugin "lint" "$lint_plugin"

ci_plugin='#!/usr/bin/env bash
acode_plugin_meta() {
  cat <<EOF
{
  "name": "ci_plugin",
  "version": "0.1.0",
  "author": "Starko",
  "description": "Lokální CI runner pro smoke testy"
}
EOF
}
acode_plugin_init() {
  WORKDIR="$1"
  mkdir -p "$WORKDIR/plugins/ci/logs"
  echo "ci_plugin: inicializováno"
}
acode_plugin_run() {
  PROJECT="${1:-$HOME/projects}"
  LOG="$WORKDIR/plugins/ci/logs/ci_$(date +%F_%H-%M).log"
  echo "ci_plugin: spouštím smoke testy pro $PROJECT" | tee "$LOG"
  if [ -f "$PROJECT/package.json" ]; then
    (cd "$PROJECT" && npm install --no-audit --no-fund) >> "$LOG" 2>&1 || echo "npm install selhalo" >> "$LOG"
    (cd "$PROJECT" && npm test) >> "$LOG" 2>&1 || echo "npm test selhalo" >> "$LOG"
  fi
  echo "CI log uložen: $LOG"
}
'
create_plugin "ci" "$ci_plugin"

backup_plugin='#!/usr/bin/env bash
acode_plugin_meta() {
  cat <<EOF
{
  "name": "backup_plugin",
  "version": "0.1.0",
  "author": "Starko",
  "description": "Zálohuje konfigurace a umožní rollback"
}
EOF
}
acode_plugin_init() {
  WORKDIR="$1"
  mkdir -p "$WORKDIR/backups"
  echo "backup_plugin: inicializováno"
}
acode_plugin_run() {
  ACTION="${1:-backup}"
  TS="$(date +%F_%H-%M-%S)"
  case "$ACTION" in
    backup)
      tar -czf "$WORKDIR/backups/acode_backup_$TS.tar.gz" -C "$WORKDIR" plugins configs install.log || echo "Záloha selhala"
      echo "Záloha vytvořena: $WORKDIR/backups/acode_backup_$TS.tar.gz"
      ;;
    list)
      ls -1 "$WORKDIR/backups"
      ;;
    restore)
      FILE="$2"
      [ -f "$FILE" ] && tar -xzf "$FILE" -C "$WORKDIR" || echo "Soubor neexistuje"
      ;;
    *)
      echo "Použití: backup|list|restore <file>"
      ;;
  esac
}
'
create_plugin "backup" "$backup_plugin"

android_helper_plugin='#!/usr/bin/env bash
acode_plugin_meta() {
  cat <<EOF
{
  "name": "android_helper_plugin",
  "version": "0.1.0",
  "author": "Starko",
  "description": "Pomocné skripty pro Android, instalace ADB, APK management"
}
EOF
}
acode_plugin_init() {
  WORKDIR="$1"
  mkdir -p "$WORKDIR/plugins/android_helper/data"
  echo "android_helper_plugin: inicializováno"
}
acode_plugin_run() {
  case "$1" in
    install-adb)
      if command -v adb >/dev/null 2>&1; then echo "adb již nainstalován"; else echo "Nainstalujte adb ručně"; fi
      ;;
    list-apks)
      adb shell pm list packages || echo "Nelze získat seznam balíčků"
      ;;
    install-apk)
      apk="$2"
      [ -f "$apk" ] && adb install -r "$apk" || echo "Zadej cestu k APK"
      ;;
    *)
      echo "android_helper_plugin: dostupné příkazy: install-adb|list-apks|install-apk <file>"
      ;;
  esac
}
'
create_plugin "android_helper" "$android_helper_plugin"

dashboard_plugin='#!/usr/bin/env bash
acode_plugin_meta() {
  cat <<EOF
{
  "name": "dashboard_plugin",
  "version": "0.1.0",
  "author": "Starko",
  "description": "Spouští lokální Flask dashboard pro reporty"
}
EOF
}
acode_plugin_init() {
  WORKDIR="$1"
  mkdir -p "$WORKDIR/dashboard"
  echo "dashboard_plugin: inicializováno"
}
acode_plugin_run() {
  if python3 -c "import flask" >/dev/null 2>&1; then
    python3 "$WORKDIR/dashboard/app.py" &
    echo "Dashboard spuštěn na pozadí"
  else
    echo "Flask není nainstalován. Nainstaluj: pip install --user flask"
  fi
}
'
create_plugin "dashboard" "$dashboard_plugin"

# ---------- DASHBOARD: jednoduchý Flask app a šablona ----------
dashboard_app='#!/usr/bin/env python3
from flask import Flask, render_template, jsonify
import os, json

app = Flask(__name__)
REPORT_DIR = os.path.expanduser(os.getenv("ACODE_REPORT_DIR", "~/.acode_dev_master/reports"))

def list_reports():
    reports = []
    if not os.path.isdir(REPORT_DIR):
        return reports
    for f in sorted(os.listdir(REPORT_DIR), reverse=True):
        if f.endswith(".json"):
            path = os.path.join(REPORT_DIR, f)
            try:
                with open(path, "r", encoding="utf-8") as fh:
                    meta = json.load(fh)
            except Exception:
                meta = {"file": f}
            meta["file"] = f
            reports.append(meta)
    return reports

@app.route("/")
def index():
    reports = list_reports()
    return render_template("index.html", reports=reports)

@app.route("/api/reports")
def api_reports():
    return jsonify(list_reports())

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
'
write_file_if_missing "${DASHBOARD_DIR}/app.py" "$dashboard_app"
make_executable "${DASHBOARD_DIR}/app.py"

dashboard_template='<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8" />
  <title>Acode Dashboard</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 2rem; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; }
    th { background: #f4f4f4; }
  </style>
</head>
<body>
  <h1>Acode Dashboard</h1>
  <p>Seznam reportů</p>
  <table>
    <thead><tr><th>Soubor</th><th>Projekt</th><th>Čas</th></tr></thead>
    <tbody>
      {% for r in reports %}
      <tr>
        <td>{{ r.file }}</td>
        <td>{{ r.project if r.project is defined else '-' }}</td>
        <td>{{ r.timestamp if r.timestamp is defined else '-' }}</td>
      </tr>
      {% endfor %}
    </tbody>
  </table>
</body>
</html>'
write_file_if_missing "${DASH_TEMPLATES_DIR}/index.html" "$dashboard_template"

# ---------- CREATE ZIP SCRIPT ----------
zip_script='#!/usr/bin/env bash
set -euo pipefail
OUT="Acode_Dev_Master.zip"
BASE_DIR="$(dirname "$0")"
cd "$BASE_DIR"
if [ -f "$OUT" ]; then
  rm -f "$OUT"
fi
zip -r "$OUT" . -x "*.bak.*" || { echo "Chyba při zipování"; exit 1; }
echo "Archiv vytvořen: $OUT"
'
write_file_if_missing "$ZIP_SCRIPT" "$zip_script"
make_executable "$ZIP_SCRIPT"

# ---------- VYTVOŘENÍ LOGU SOUBORU pokud chybí ----------
if [ ! -f "$INSTALL_LOG" ]; then
  touch "$INSTALL_LOG"
  log "Vytvořen prázdný log: $INSTALL_LOG"
fi

# ---------- PATH WRAPPER (idempotent) ----------
BIN_DIR="${WORKDIR}/bin"
ensure_dir "$BIN_DIR"
acode_wrapper="${BIN_DIR}/acode"
acode_wrapper_content='#!/usr/bin/env bash
case "$1" in
  analyze) shift; '"${CORE_DIR}"'/analyze.sh "$@" ;;
  improve) shift; '"${CORE_DIR}"'/improve.sh "$@" ;;
  aireview) shift; '"${CORE_DIR}"'/ai-review.sh "$@" ;;
  *) echo "acode wrapper: analyze|improve|aireview" ;;
esac
'
write_file_if_missing "$acode_wrapper" "$acode_wrapper_content"
make_executable "$acode_wrapper"

# Add to ~/.profile if not present
if ! grep -qxF "export PATH=\"${BIN_DIR}:\$PATH\"" "${HOME}/.profile" 2>/dev/null; then
  echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "${HOME}/.profile"
  log "Přidáno do PATH v ~/.profile: ${BIN_DIR}"
fi

# ---------- NAČTENÍ PLUGINŮ (volitelné) ----------
log "Načítám pluginy (pokud existují)"
shopt -s nullglob
for p in "${PLUGINS_DIR}"/*/plugin.sh; do
  if [ -f "$p" ]; then
    log "Načítám plugin: $p"
    ( source "$p" 2>/dev/null && type acode_plugin_init >/dev/null 2>&1 && acode_plugin_init "$WORKDIR" ) || log "Plugin $p nelze inicializovat"
  fi
done
shopt -u nullglob

# ---------- DOKONČENÍ ----------
log "Inicializace dokončena. Struktura vytvořena v $WORKDIR"
log "Spusť $WORKDIR/master_install.sh znovu pro interaktivní menu nebo použij wrapper acode."
cat <<EOF

Hotovo.

Doporučené další kroky:
- restartuj shell nebo spusť: source ~/.profile
- zkontroluj log: $INSTALL_LOG
- pokud chceš vytvořit ZIP balíček, spusť: $ZIP_SCRIPT

EOF

# Pokud byl skript spuštěn přímo, nabídni menu
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  log "Spouštím interaktivní menu"
  while true; do
    echo "============================="
    echo "  Acode Dev Master Installer"
    echo "============================="
    echo "1) Spustit audit plugin"
    echo "2) Spustit lint plugin"
    echo "3) Vytvořit zálohu (backup plugin)"
    echo "4) Spustit dashboard (dashboard plugin)"
    echo "5) Vytvořit ZIP balíček"
    echo "6) Ukončit"
    read -r -p "Vyber volbu: " CHOICE
    case "$CHOICE" in
      1) bash "${PLUGINS_DIR}/audit/plugin.sh" run "${PLUGINS_DIR}" || true ;;
      2) bash "${PLUGINS_DIR}/lint/plugin.sh" run "${HOME}/projects" || true ;;
      3) bash "${PLUGINS_DIR}/backup/plugin.sh" run || true ;;
      4) bash "${PLUGINS_DIR}/dashboard/plugin.sh" run || true ;;
      5) bash "$ZIP_SCRIPT" || true ;;
      6) log "Ukončuji..."; exit 0 ;;
      *) echo "Neplatná volba." ;;
    esac
    read -r -p "Stiskni Enter pro pokračování..."
  done
fi
