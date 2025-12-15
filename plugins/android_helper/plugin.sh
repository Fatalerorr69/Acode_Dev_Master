#!/usr/bin/env bash
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
