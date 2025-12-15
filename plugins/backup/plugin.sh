#!/usr/bin/env bash
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
