#!/usr/bin/env bash
set -euo pipefail
WORKDIR="${HOME}/.acode_dev_master"
log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$WORKDIR/install.log"; }

menu() {
  CHOICE=$(whiptail --title "Acode Installer" --menu "Vyber akci" 20 70 10 \
    "1" "Instalace základních modulů" \
    "2" "AI moduly" \
    "3" "Android / Acode" \
    "4" "WSL / VM" \
    "5" "LCD / RPi5" \
    "6" "Správa pluginů" \
    "7" "Vytvořit ZIP" \
    "8" "Ukončit" 3>&1 1>&2 2>&3) || exit 0
  echo "$CHOICE"
}

while true; do
  case "$(menu)" in
    1) bash "$WORKDIR/master_install_core.sh" ;;
    2) bash "$WORKDIR/master_install_ai.sh" ;;
    3) bash "$WORKDIR/master_install_android.sh" ;;
    4) bash "$WORKDIR/master_install_wsl.sh" ;;
    5) bash "$WORKDIR/master_install_lcd.sh" ;;
    6) bash "$WORKDIR/gui/plugin_manager.sh" ;;
    7) bash "$WORKDIR/create_zip.sh" ;;
    8) log "Ukončuji"; exit 0 ;;
  esac
done
