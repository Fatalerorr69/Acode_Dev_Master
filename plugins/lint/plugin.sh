#!/usr/bin/env bash
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
