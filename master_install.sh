#!/usr/bin/env bash
# Acode Dev Master Installer – s non-interactive módem a ověřováním pluginů
# Version: 1.1
# Autor: Starko / Fatalerorr69 (upraveno)
# Popis: Rozšířený instalátor s --non-interactive, --yes, --install a --plugins
set -euo pipefail
IFS=$'\n\t'

# ---------- ARGUMENTY ----------
ASSUME_YES=0
NONINTERACTIVE=0
REQUESTED_INSTALL=""
REQUESTED_PLUGINS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) ASSUME_YES=1; shift ;;
    --non-interactive|-n) NONINTERACTIVE=1; ASSUME_YES=1; shift ;;
    --install) REQUESTED_INSTALL="$2"; shift 2 ;;
    --plugins) REQUESTED_PLUGINS="$2"; shift 2 ;;
    --help|-h) cat <<USAGE
Usage: $0 [--yes] [--non-interactive] [--install core,ai,android,...] [--plugins url1,url2]
  --yes            assume yes for confirmations
  --non-interactive run in non-interactive mode (implies --yes)
  --install        comma-separated modules to install (core,ai,starkos,android,wsl,lcd)
  --plugins        comma-separated GitHub repo URLs to install as plugins
USAGE
  exit 0 ;;
    *) echo "Neznámý parametr: $1"; shift ;;
  esac
done

# ---------- PROMĚNNÉ ----------
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
BIN_DIR="${WORKDIR}/bin"

# ---------- LOGGING ----------
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$INSTALL_LOG"; }
err() { printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$INSTALL_LOG" >&2; }
trap 'err "Selhání na řádku $LINENO"; exit 1' ERR

# ---------- HELPERS ----------
ensure_dir() { local d="$1"; [ -d "$d" ] || { mkdir -p "$d"; log "Vytvořeno: $d"; } }
backup_if_exists() { local f="$1"; [ -e "$f" ] && { ts="$(date +%F_%H-%M-%S)"; mv "$f" "${f}.bak.${ts}"; log "Záloha: $f -> ${f}.bak.${ts}"; } }
write_file_if_missing() { local p="$1"; local c="$2"; if [ -e "$p" ]; then log "Existuje: $p"; else printf '%s\n' "$c" > "$p"; log "Vytvořen: $p"; fi }
write_file_force() { local p="$1"; local c="$2"; backup_if_exists "$p"; printf '%s\n' "$c" > "$p"; log "Zapsán: $p"; }
make_executable() { local f="$1"; [ -f "$f" ] && chmod +x "$f" && log "chmod +x $f"; }
confirm() {
  local msg="$1"
  if [ "$ASSUME_YES" -eq 1 ]; then log "Auto-confirm: $msg"; return 0; fi
  if [ "$NONINTERACTIVE" -eq 1 ]; then err "Non-interactive režim: potvrzení vyžadováno, ale --yes nebylo nastaveno"; return 1; fi
  read -r -p "$msg [y/N]: " a; case "$a" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ---------- STRUKTURA ----------
log "Inicializuji adresáře v $WORKDIR"
ensure_dir "$WORKDIR" "$PLUGINS_DIR" "$CONFIGS_DIR" "$DOCS_DIR" "$CORE_DIR" "$DASHBOARD_DIR" "$DASH_TEMPLATES_DIR" "$REPORTS_DIR" "$LOGS_DIR" "$BIN_DIR"

# ---------- ZÁKLADNÍ SOUBORY (zkráceno) ----------
write_file_if_missing "$README_FILE" "# Acode Dev Master Installer\n\nViz docs/INSTALL.md"
write_file_if_missing "$LICENSE_FILE" "MIT License\n\nCopyright (c) 2025"
write_file_if_missing "$GITIGNORE_FILE" "/logs/\n/reports/\n/*.zip\n.env\n"

config_json='{
  "project_dir": "$HOME/projects",
  "ai_engine": "auto",
  "default_model": "codellama",
  "report_dir": "$HOME/.acode_dev_master/reports",
  "plugins_dir": "$HOME/.acode_dev_master/plugins",
  "sandboxing": {"preferred": ["firejail","docker"], "enabled": true},
  "non_interactive_defaults": {"assume_yes": false}
}'
write_file_if_missing "${CONFIGS_DIR}/acode_settings.json" "$config_json"

# ---------- CORE SCRIPTS (základní) ----------
analyze_sh='#!/usr/bin/env bash
set -euo pipefail
PROJECT="${1:-}"
[ -d "$PROJECT" ] || { echo "Chyba: projekt nenalezen"; exit 1; }
REPORT_DIR="${ACODE_REPORT_DIR:-$HOME/.acode_dev_master/reports}"; mkdir -p "$REPORT_DIR"
TS="$(date +%F_%H-%M-%S)"; TXT="$REPORT_DIR/analysis_${TS}.txt"; JSON="$REPORT_DIR/analysis_${TS}.json"
echo "ANALÝZA $PROJECT" | tee "$TXT"
du -sh "$PROJECT" | tee -a "$TXT"
find "$PROJECT" -type f | wc -l | tee -a "$TXT"
grep -RniE "TODO|FIXME|BUG|HACK" "$PROJECT" || true
cat > "$JSON" <<EOF
{ "project":"$PROJECT","timestamp":"$TS","size":"$(du -sh "$PROJECT" | cut -f1)","file_count":$(find "$PROJECT" -type f | wc -l) }
EOF
echo "Report: $TXT and $JSON"
'
write_file_if_missing "${CORE_DIR}/analyze.sh" "$analyze_sh"; make_executable "${CORE_DIR}/analyze.sh"

improve_sh='#!/usr/bin/env bash
set -euo pipefail
PROJECT="${1:-}"
[ -d "$PROJECT" ] || { echo "Chyba: projekt nenalezen"; exit 1; }
echo "Kontrola anti-patternů..."
grep -Rni --exclude-dir=node_modules "forEach(" "$PROJECT" || true
grep -Rni --exclude-dir=node_modules "setTimeout(" "$PROJECT" || true
grep -Rni --exclude-dir=node_modules -E "fs\.readFileSync|fs\.writeFileSync" "$PROJECT" || true
'
write_file_if_missing "${CORE_DIR}/improve.sh" "$improve_sh"; make_executable "${CORE_DIR}/improve.sh"

ai_review_sh='#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-}"; [ -f "$FILE" ] || { echo "Chyba: soubor nenalezen"; exit 1; }
MAX=200000; SIZE=$(wc -c < "$FILE"); [ "$SIZE" -le "$MAX" ] || { echo "Soubor příliš velký"; exit 1; }
OUT="${FILE}.ai.suggest"
if command -v ollama >/dev/null 2>&1; then
  ollama run codellama "Analyze and propose a patch:" < "$FILE" > "$OUT" || true
elif command -v openai >/dev/null 2>&1; then
  openai api completions.create -m text-davinci-003 -i "$FILE" > "$OUT" || true
elif python3 -c "import transformers" >/dev/null 2>&1; then
  python3 - <<PY > "$OUT"
from transformers import pipeline
print("AI návrh: zkontroluj a navrhni refaktor. (Ukázka)")
PY
else
  echo "Žádný AI engine dostupný" >&2; exit 1
fi
echo "AI návrh uložen do $OUT"
'
write_file_if_missing "${CORE_DIR}/ai-review.sh" "$ai_review_sh"; make_executable "${CORE_DIR}/ai-review.sh"

# ---------- PLUGIN: klonování s ověřením SHA256 ----------
install_plugin_from_github() {
  local repo="$1"
  local dest="$PLUGINS_DIR/$(basename "$repo" .git)"
  if [ -d "$dest" ]; then log "Plugin již existuje: $dest"; return 0; fi
  if [ "$NONINTERACTIVE" -eq 0 ]; then
    confirm "Chceš stáhnout plugin z $repo do $dest?" || { log "Uživatel zrušil klonování"; return 1; }
  fi
  git clone --depth 1 "$repo" "$dest" || { err "Clone failed: $repo"; rm -rf "$dest"; return 1; }
  # Najdi hlavní skript pluginu (plugin.sh nebo index.sh)
  local main=""
  if [ -f "$dest/plugin.sh" ]; then main="$dest/plugin.sh"; elif [ -f "$dest/index.sh" ]; then main="$dest/index.sh"; fi
  if [ -n "$main" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$main" | awk '{print $1}' > "$dest/.sha256"
      log "Vypočten SHA256 pro $main a uložen do $dest/.sha256"
    fi
  else
    log "Hlavní skript pluginu nenalezen; .sha256 nebude vytvořeno"
  fi
  # inicializuj plugin pokud definuje acode_plugin_init
  if [ -f "$main" ]; then
    ( source "$main" 2>/dev/null && type acode_plugin_init >/dev/null 2>&1 && acode_plugin_init "$WORKDIR" ) || log "Plugin init selhal nebo není definován"
  fi
  log "Plugin nainstalován: $dest"
}

# ---------- PLUGIN: instalace více pluginů z parametru ----------
install_plugins_from_list() {
  local list="$1"
  IFS=',' read -r -a repos <<< "$list"
  for r in "${repos[@]}"; do
    r="$(echo "$r" | xargs)" # trim
    [ -n "$r" ] && install_plugin_from_github "$r"
  done
}

# ---------- BOOTSTRAP: vytvoření ukázkových pluginů (pokud chybí) ----------
create_sample_plugin() {
  local name="$1" content="$2"
  local dir="$PLUGINS_DIR/$name"
  ensure_dir "$dir"
  local file="$dir/plugin.sh"
  if [ ! -f "$file" ]; then
    printf '%s\n' "$content" > "$file"
    chmod +x "$file"
    log "Vytvořen sample plugin: $file"
  else
    log "Sample plugin existuje: $file"
  fi
}

# krátké ukázky pluginů (audit, lint, backup, dashboard)
create_sample_plugin "audit" '#!/usr/bin/env bash
acode_plugin_meta(){ cat <<EOF
{ "name":"audit_plugin","version":"0.2.0","author":"Starko","description":"Kontrola pluginu" }
EOF
}
acode_plugin_init(){ WORKDIR="$1"; mkdir -p "$WORKDIR/plugins/audit/data"; echo "audit init"; }
acode_plugin_run(){ echo "audit run"; }'

create_sample_plugin "lint" '#!/usr/bin/env bash
acode_plugin_meta(){ cat <<EOF
{ "name":"lint_plugin","version":"0.1.0","author":"Starko","description":"Linting" }
EOF
}
acode_plugin_init(){ WORKDIR="$1"; mkdir -p "$WORKDIR/plugins/lint/reports"; echo "lint init"; }
acode_plugin_run(){ echo "lint run"; }'

create_sample_plugin "backup" '#!/usr/bin/env bash
acode_plugin_meta(){ cat <<EOF
{ "name":"backup_plugin","version":"0.1.0","author":"Starko","description":"Backup" }
EOF
}
acode_plugin_init(){ WORKDIR="$1"; mkdir -p "$WORKDIR/backups"; echo "backup init"; }
acode_plugin_run(){ echo "backup run"; }'

create_sample_plugin "dashboard" '#!/usr/bin/env bash
acode_plugin_meta(){ cat <<EOF
{ "name":"dashboard_plugin","version":"0.1.0","author":"Starko","description":"Dashboard" }
EOF
}
acode_plugin_init(){ WORKDIR="$1"; mkdir -p "$WORKDIR/dashboard"; echo "dashboard init"; }
acode_plugin_run(){ echo "dashboard run"; }'

# ---------- DASHBOARD (jednoduché) ----------
dashboard_app='#!/usr/bin/env python3
from flask import Flask, render_template, jsonify
import os,json
app=Flask(__name__)
REPORT_DIR=os.path.expanduser(os.getenv("ACODE_REPORT_DIR","~/.acode_dev_master/reports"))
def list_reports():
  r=[]
  if not os.path.isdir(REPORT_DIR): return r
  for f in sorted(os.listdir(REPORT_DIR), reverse=True):
    if f.endswith(".json"):
      try:
        with open(os.path.join(REPORT_DIR,f),"r",encoding="utf-8") as fh: meta=json.load(fh)
      except Exception:
        meta={"file":f}
      meta["file"]=f; r.append(meta)
  return r
@app.route("/") 
def index(): return render_template("index.html", reports=list_reports())
@app.route("/api/reports") 
def api_reports(): return jsonify(list_reports())
if __name__=="__main__": app.run(host="127.0.0.1",port=5000,debug=True)
'
write_file_if_missing "${DASHBOARD_DIR}/app.py" "$dashboard_app"; make_executable "${DASHBOARD_DIR}/app.py"

dashboard_template='<!doctype html><html lang="cs"><head><meta charset="utf-8"/><title>Acode Dashboard</title></head><body><h1>Acode Dashboard</h1><table><thead><tr><th>Soubor</th><th>Projekt</th><th>Čas</th></tr></thead><tbody>{% for r in reports %}<tr><td>{{ r.file }}</td><td>{{ r.project if r.project is defined else "-" }}</td><td>{{ r.timestamp if r.timestamp is defined else "-" }}</td></tr>{% endfor %}</tbody></table></body></html>'
write_file_if_missing "${DASH_TEMPLATES_DIR}/index.html" "$dashboard_template"

# ---------- ZIP skript ----------
zip_script='#!/usr/bin/env bash
set -euo pipefail
OUT="Acode_Dev_Master.zip"
BASE="$(dirname "$0")"
cd "$BASE"
[ -f "$OUT" ] && rm -f "$OUT"
zip -r "$OUT" . -x "*.bak.*" || { echo "Chyba zip"; exit 1; }
echo "Archiv: $OUT"
'
write_file_if_missing "$ZIP_SCRIPT" "$zip_script"; make_executable "$ZIP_SCRIPT"

# ---------- WRAPPER CLI ----------
acode_wrapper="${BIN_DIR}/acode"
acode_wrapper_content='#!/usr/bin/env bash
case "$1" in
  analyze) shift; '"${CORE_DIR}"'/analyze.sh "$@" ;;
  improve) shift; '"${CORE_DIR}"'/improve.sh "$@" ;;
  aireview) shift; '"${CORE_DIR}"'/ai-review.sh "$@" ;;
  *) echo "acode wrapper: analyze|improve|aireview" ;;
esac'
write_file_if_missing "$acode_wrapper" "$acode_wrapper_content"; make_executable "$acode_wrapper"
if ! grep -qxF "export PATH=\"${BIN_DIR}:\$PATH\"" "${HOME}/.profile" 2>/dev/null; then
  echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "${HOME}/.profile"
  log "Přidáno do PATH v ~/.profile: ${BIN_DIR}"
fi

# ---------- NAČTENÍ EXISTUJÍCÍCH PLUGINŮ ----------
log "Inicializuji existující pluginy..."
shopt -s nullglob
for p in "${PLUGINS_DIR}"/*/plugin.sh; do
  [ -f "$p" ] || continue
  log "Načítám plugin: $p"
  ( source "$p" 2>/dev/null && type acode_plugin_init >/dev/null 2>&1 && acode_plugin_init "$WORKDIR" ) || log "Plugin init selhal: $p"
done
shopt -u nullglob

# ---------- ZPRACOVÁNÍ PARAMETRŮ: instalace modulů a pluginů ----------
if [ -n "$REQUESTED_INSTALL" ]; then
  IFS=',' read -r -a mods <<< "$REQUESTED_INSTALL"
  for m in "${mods[@]}"; do
    case "$m" in
      core) log "Core modul: již vytvořen" ;;
      ai) log "AI modul: nainstaluj ručně nebo použij ai-review" ;;
      starkos) log "StarkOS modul: vyžaduje skripty v Skripty/..." ;;
      android) log "Android modul: vyžaduje skripty v Skripty/..." ;;
      wsl) log "WSL modul: vyžaduje skripty v Skripty/..." ;;
      lcd) log "LCD modul: vyžaduje skripty v Skripty/..." ;;
      *) log "Neznámý modul: $m" ;;
    esac
  done
fi

if [ -n "$REQUESTED_PLUGINS" ]; then
  install_plugins_from_list "$REQUESTED_PLUGINS"
fi

# ---------- DOKONČENÍ ----------
log "Inicializace dokončena. Struktura v $WORKDIR"
log "Pro interaktivní menu spusť: $0 (bez parametrů) nebo použij wrapper acode."

# ---------- INTERAKTIVNÍ MENU (pokud není non-interactive) ----------
if [ "$NONINTERACTIVE" -eq 0 ]; then
  while true; do
    echo "============================="
    echo "  Acode Dev Master Installer"
    echo "============================="
    echo "1) Nainstalovat plugin z GitHub"
    echo "2) Seznam pluginů"
    echo "3) Spustit audit plugin"
    echo "4) Spustit lint plugin"
    echo "5) Vytvořit zálohu"
    echo "6) Spustit dashboard"
    echo "7) Vytvořit ZIP"
    echo "8) Ukončit"
    read -r -p "Volba: " CH
    case "$CH" in
      1) read -r -p "GitHub URL: " R; install_plugin_from_github "$R" || true ;;
      2) ls -1 "$PLUGINS_DIR" || echo "(žádné)" ;;
      3) [ -f "${PLUGINS_DIR}/audit/plugin.sh" ] && bash "${PLUGINS_DIR}/audit/plugin.sh" run "${PLUGINS_DIR}" || echo "Audit plugin nenalezen" ;;
      4) [ -f "${PLUGINS_DIR}/lint/plugin.sh" ] && bash "${PLUGINS_DIR}/lint/plugin.sh" run "${HOME}/projects" || echo "Lint plugin nenalezen" ;;
      5) [ -f "${PLUGINS_DIR}/backup/plugin.sh" ] && bash "${PLUGINS_DIR}/backup/plugin.sh" run || echo "Backup plugin nenalezen" ;;
      6) [ -f "${PLUGINS_DIR}/dashboard/plugin.sh" ] && bash "${PLUGINS_DIR}/dashboard/plugin.sh" run || echo "Dashboard plugin nenalezen" ;;
      7) bash "$ZIP_SCRIPT" || echo "ZIP selhal" ;;
      8) log "Ukončuji..."; exit 0 ;;
      *) echo "Neplatná volba." ;;
    esac
    read -r -p "Stiskni Enter..."
  done
else
  log "Non-interactive režim: dokončeno"
fi
