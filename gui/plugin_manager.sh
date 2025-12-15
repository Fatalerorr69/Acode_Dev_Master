#!/usr/bin/env bash
WORKDIR="${HOME}/.acode_dev_master"
PLUGINS_DIR="$WORKDIR/plugins"
echo "Dostupné pluginy:"
ls "$PLUGINS_DIR" || echo "(žádné)"
read -p "Chceš plugin odstranit (název) nebo Enter: " del
[ -n "$del" ] && rm -rf "$PLUGINS_DIR/$del" && echo "Plugin $del odstraněn."
