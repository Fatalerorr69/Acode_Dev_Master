# 📦 Acode – Kompletní integrovaný systém pro analýzu, optimalizaci a rozšíření

Tento dokument definuje **jednotný instalační a provozní systém** pro Acode (Android), který integruje:

- analýzu kódu
- návrhy optimalizace
- refaktorování s AI
- audit pluginů
- profesionální nastavení terminálu
- jednotný workflow

Cílem je **mobilní IDE na úrovni desktopu**.

---

## 1️⃣ Struktura po instalaci

```
$HOME/acode-suite/
├── install.sh              # JEDINÝ instalační skript
├── acode.env               # Centrální konfigurace
│
├── core/
│   ├── analyze.sh          # Statická analýza
│   ├── improve.sh          # Optimalizace
│   ├── ai-review.sh        # AI analýza (OpenAI / Ollama)
│
├── plugins/
│   └── audit.sh            # Audit Acode pluginů
│
├── terminal/
│   └── setup.sh            # Terminál + nástroje
│
├── reports/
└── dashboard/              # připraveno pro web GUI
```

---

## 2️⃣ JEDINÝ INSTALAČNÍ SKRIPT – `install.sh`

```bash
#!/data/data/com.termux/files/usr/bin/bash

set -e

BASE="$HOME/acode-suite"

mkdir -p "$BASE"/{core,plugins,terminal,reports,dashboard}

pkg update -y
pkg install -y git nodejs python clang jq ripgrep zsh curl

# ===== ENV =====
cat <<EOF > "$BASE/acode.env"
PROJECT_DIR=$HOME/projects
AI_ENGINE=ollama
DEFAULT_MODEL=codellama
EOF

# ===== ANALYZE =====
cat <<'EOF' > "$BASE/core/analyze.sh"
#!/data/data/com.termux/files/usr/bin/bash
PROJECT="$1"
REPORT="$HOME/acode-suite/reports/analysis_$(date +%F_%H-%M).txt"
mkdir -p $(dirname "$REPORT")

echo "== ANALÝZA ==" | tee "$REPORT"
du -sh "$PROJECT" | tee -a "$REPORT"
find "$PROJECT" -type f | wc -l | tee -a "$REPORT"
grep -RniE "TODO|FIXME|BUG|HACK" "$PROJECT" | tee -a "$REPORT"
EOF

chmod +x "$BASE/core/analyze.sh"

# ===== IMPROVE =====
cat <<'EOF' > "$BASE/core/improve.sh"
#!/data/data/com.termux/files/usr/bin/bash
PROJECT="$1"
echo "== OPTIMALIZACE =="
grep -Rni "forEach(" "$PROJECT"
grep -Rni "setTimeout(" "$PROJECT"
EOF

chmod +x "$BASE/core/improve.sh"

# ===== AI REVIEW =====
cat <<'EOF' > "$BASE/core/ai-review.sh"
#!/data/data/com.termux/files/usr/bin/bash
FILE="$1"
ollama run codellama "Analyze and refactor this code:" < "$FILE"
EOF

chmod +x "$BASE/core/ai-review.sh"

# ===== PLUGINS AUDIT =====
cat <<'EOF' > "$BASE/plugins/audit.sh"
#!/data/data/com.termux/files/usr/bin/bash
PLUGIN_DIR="$HOME/.acode/plugins"
for p in "$PLUGIN_DIR"/*; do
  echo "PLUGIN: $(basename "$p")"
  [ -f "$p/package.json" ] && jq '.name,.version' "$p/package.json"
done
EOF

chmod +x "$BASE/plugins/audit.sh"

# ===== TERMINAL =====
cat <<'EOF' > "$BASE/terminal/setup.sh"
#!/data/data/com.termux/files/usr/bin/bash
pkg install -y zsh
chsh -s zsh

echo "alias analyze='$HOME/acode-suite/core/analyze.sh'" >> ~/.zshrc
echo "alias improve='$HOME/acode-suite/core/improve.sh'" >> ~/.zshrc
echo "alias aireview='$HOME/acode-suite/core/ai-review.sh'" >> ~/.zshrc
source ~/.zshrc
EOF

chmod +x "$BASE/terminal/setup.sh"

"$BASE/terminal/setup.sh"

echo "✔ Acode Suite nainstalováno"
```

---

## 3️⃣ Použití (denní workflow)

```bash
analyze ~/projects/app
improve ~/projects/app
aireview src/main.js
bash ~/acode-suite/plugins/audit.sh
```

---

## 4️⃣ Doporučené Acode pluginy

- ESLint
- Prettier
- Git
- Terminal
- AI Assistant

---

## 5️⃣ Progresivní architektura

- 100 % skriptovatelné
- rozšiřitelné o web dashboard
- připravené pro StarkOS / UltraOS
- AI není hračka, ale **kontrolní mechanismus**

---

## 6️⃣ Další rozšíření (volitelné)

- lokální web GUI (Flask / Node)
- CI pipeline z mobilu
- AI paměť projektu
- automatické testy

---

📌 **Toto je plnohodnotné vývojové prostředí, ne kompromis.**

