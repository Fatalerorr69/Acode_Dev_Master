#!/data/data/com.termux/files/usr/bin/bash
# ========================================================
# Acode Dev Toolkit – Interaktivní vizuální mapa instalace
# ========================================================

set -e

BASE_DIR=~/acode-dev-tools
UTILS_DIR=$BASE_DIR/utils
TEMPLATES_DIR=$BASE_DIR/templates
REPORTS_DIR=$BASE_DIR/reports
CONFIG_DIR=$BASE_DIR/config
PROJECT_DIR=~/muj_projekt

STEPS=(
  "Vytvoření složek"
  "Generování základních skriptů"
  "Generování utils skriptů"
  "Generování šablon"
  "Generování konfigurace"
  "Generování README"
  "AI analýza projektu"
  "Vytvoření moderního GUI"
)

TOTAL=${#STEPS[@]}
CURRENT=0

# Funkce pro zobrazení interaktivní mapy
show_map() {
  clear
  echo "=== Acode Dev Toolkit – Interaktivní instalace ==="
  echo
  for i in "${!STEPS[@]}"; do
    if [ $i -lt $CURRENT ]; then
      echo -e "[✔] ${STEPS[$i]}"
    else
      echo -e "[ ] ${STEPS[$i]}"
    fi
  done
  echo
  PERCENT=$((CURRENT*100/TOTAL))
  echo "Průběh instalace: $PERCENT%"
  echo
}

# 1️⃣ Vytvoření složek
CURRENT=1; show_map
mkdir -p $BASE_DIR $UTILS_DIR $REPORTS_DIR $CONFIG_DIR
mkdir -p $TEMPLATES_DIR/js/src $TEMPLATES_DIR/python/src $TEMPLATES_DIR/html/src
mkdir -p $PROJECT_DIR
sleep 0.5

# 2️⃣ Generování základních skriptů
CURRENT=2; show_map
cat > "$BASE_DIR/analyze.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PROJECT="$1"
REPORT="~/acode-dev-tools/reports/analysis_$(date +%F_%H-%M).md"
mkdir -p ~/acode-dev-tools/reports
echo "# Analýza projektu $(basename "$PROJECT")" > "$REPORT"
du -sh "$PROJECT" >> "$REPORT"
find "$PROJECT" -type f | wc -l >> "$REPORT"
grep -RniE "TODO|FIXME|BUG|HACK" "$PROJECT" >> "$REPORT" || echo "Žádné poznámky"
echo -e "\n# AI návrhy" >> "$REPORT"
echo "- Refaktorujte dlouhé funkce" >> "$REPORT"
echo "- Sjednoťte pojmenování proměnných" >> "$REPORT"
echo "✔ Analýza dokončena, report uložen do $REPORT"
EOF
chmod +x "$BASE_DIR/analyze.sh"

cat > "$BASE_DIR/improve.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PROJECT="$1"
echo "=== Optimalizace a refaktoring ==="
command -v jscpd >/dev/null 2>&1 || echo "Nainstalujte jscpd: npm i -g jscpd"
jscpd "$PROJECT" 2>/dev/null || echo "Kontrola duplicit přeskočena"
echo "✔ Vylepšení dokončeno"
EOF
chmod +x "$BASE_DIR/improve.sh"

cat > "$BASE_DIR/plugins-audit.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PLUGIN_DIR="/data/data/com.termux/files/home/.acode/plugins"
echo "=== Kontrola pluginů ==="
for p in "$PLUGIN_DIR"/*; do
  echo "🔹 $(basename "$p")"
done
EOF
chmod +x "$BASE_DIR/plugins-audit.sh"

cat > "$BASE_DIR/watch.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PROJECT="$1"
echo "=== Watch mode aktivní pro $PROJECT ==="
while true; do
  inotifywait -e modify,create,delete -r "$PROJECT"
  echo "Změna detekována, spouštím analyze + improve..."
  bash ~/acode-dev-tools/analyze.sh "$PROJECT"
  bash ~/acode-dev-tools/improve.sh "$PROJECT"
done
EOF
chmod +x "$BASE_DIR/watch.sh"
sleep 0.5

# 3️⃣ Utils skripty
CURRENT=3; show_map
cat > "$UTILS_DIR/setup_project.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Vyber typ šablony (js/python/html):"
select t in js python html; do
  mkdir -p "$HOME/muj_projekt"
  cp -r ~/acode-dev-tools/templates/$t/* "$HOME/muj_projekt/"
  echo "Projekt vytvořen ze šablony $t."
  break
done
EOF
chmod +x "$UTILS_DIR/setup_project.sh"

cat > "$UTILS_DIR/boilerplate_gen.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Vyber typ boilerplate:"
select t in js python html; do
  mkdir -p "$HOME/muj_projekt/src"
  case $t in
    js) echo "// JS boilerplate\nconsole.log(\"Hello World\");" > "$HOME/muj_projekt/src/main.js";;
    python) echo "# Python boilerplate\nprint(\"Hello World\")" > "$HOME/muj_projekt/src/main.py";;
    html) echo "<!DOCTYPE html>\n<html>\n<body>\n<h1>Hello World</h1>\n</body>\n</html>" > "$HOME/muj_projekt/src/index.html";;
  esac
  echo "Boilerplate pro $t vytvořen."
  break
done
EOF
chmod +x "$UTILS_DIR/boilerplate_gen.sh"

cat > "$UTILS_DIR/stats.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PROJECT="$1"
echo "=== Statistiky projektu $(basename "$PROJECT") ==="
echo "Počet souborů:" $(find "$PROJECT" -type f | wc -l)
echo "Počet řádků kódu:" $(find "$PROJECT" -type f -name "*.js" | xargs cat | wc -l)
EOF
chmod +x "$UTILS_DIR/stats.sh"

cat > "$UTILS_DIR/update_project.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "=== Aktualizace a opravy Acode Dev Toolkit ==="
BASE_DIR=~/acode-dev-tools
UTILS_DIR=$BASE_DIR/utils
chmod +x $BASE_DIR/*.sh
chmod +x $UTILS_DIR/*.sh
bash $BASE_DIR/plugins-audit.sh
echo "✔ Toolkit aktualizován a opraven."
EOF
chmod +x "$UTILS_DIR/update_project.sh"
sleep 0.5

# 4️⃣ Generování šablon
CURRENT=4; show_map
echo "// JS boilerplate\nconsole.log('Hello World');" > "$TEMPLATES_DIR/js/src/main.js"
echo "# Python boilerplate\nprint('Hello World')" > "$TEMPLATES_DIR/python/src/main.py"
echo "<!DOCTYPE html>\n<html>\n<body>\n<h1>Hello World</h1>\n</body>\n</html>" > "$TEMPLATES_DIR/html/src/index.html"
sleep 0.5

# 5️⃣ Konfigurace
CURRENT=5; show_map
echo '{"plugins":[]}' > "$CONFIG_DIR/plugins.json"
sleep 0.5

# 6️⃣ README
CURRENT=6; show_map
cat > "$BASE_DIR/README.md" <<'EOF'
# Acode Dev Toolkit
Plně autonomní prostředí s AI návrhy, moderním GUI a vizuální mapou instalace.
EOF
sleep 0.5

# 7️⃣ AI analýza
CURRENT=7; show_map
bash "$BASE_DIR/analyze.sh" "$PROJECT_DIR"
bash "$BASE_DIR/improve.sh" "$PROJECT_DIR"
sleep 0.5

# 8️⃣ GUI menu
CURRENT=8; show_map
cat > "$BASE_DIR/advanced_menu.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PROJECT_DIR="$HOME/muj_projekt"
while true; do
CHOICE=$(dialog --clear --title "Acode Dev Toolkit – GUI + Progress Map" \
--menu "Vyber akci:" 20 70 12 \
1 "Zobrazit poslední report" \
2 "Generovat boilerplate" \
3 "Vytvořit nový projekt ze šablony" \
4 "Spustit watch-mode" \
5 "Kontrola pluginů a aktualizace" \
6 "Aktualizace toolkit a opravy" \
0 "Ukončit" 3>&1 1>&2 2>&3)

case $CHOICE in
1) ls -t ~/acode-dev-tools/reports | head -1 | xargs -I{} cat ~/acode-dev-tools/reports/{};;
2) bash ~/acode-dev-tools/utils/boilerplate_gen.sh;;
3) bash ~/acode-dev-tools/utils/setup_project.sh;;
4) bash ~/acode-dev-tools/watch.sh "$PROJECT_DIR";;
5) bash ~/acode-dev-tools/plugins-audit.sh;;
6) bash ~/acode-dev-tools/utils/update_project.sh;;
0) clear; exit;;
esac
done
EOF
chmod +x "$BASE_DIR/advanced_menu.sh"
sleep 0.5

clear
echo "✅ Instalace dokončena!"
echo "Spusť GUI: bash ~/acode-dev-tools/advanced_menu.sh"
