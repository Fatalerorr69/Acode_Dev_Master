#!/usr/bin/env bash
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
