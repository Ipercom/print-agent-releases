#!/bin/bash
# =============================================
#   1Acces Print Collector Agent - Installation (macOS)
# =============================================
# Auto-detecte Apple Silicon vs Intel et telecharge le binaire signe + notarise
# depuis GitHub Releases (fallback erp.1acces.com/downloads).
# Installe un LaunchDaemon pour demarrage automatique.
# =============================================

set -e

echo "============================================="
echo "  1Acces Print Collector Agent - Installation"
echo "  (macOS)"
echo "============================================="
echo ""

# 1. Verifier root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Veuillez executer ce script en tant que root (sudo)"
    exit 1
fi

INSTALL_DIR="/opt/1acces/print-agent"
LAUNCH_DAEMON="/Library/LaunchDaemons/com.1acces.print-agent.plist"
VERSION="${PRINT_AGENT_VERSION:-latest}"

GITHUB_BASE="https://github.com/Ipercom/print-agent-releases/releases"
if [ "$VERSION" = "latest" ]; then
    GITHUB_URL="${GITHUB_BASE}/latest/download"
else
    GITHUB_URL="${GITHUB_BASE}/download/${VERSION}"
fi
FALLBACK_URL="https://erp.1acces.com/downloads"

# 2. Detecter l'architecture
ARCH="$(uname -m)"
case "$ARCH" in
    arm64)
        BINARY="print-agent-macos-arm64"
        ;;
    x86_64)
        BINARY="print-agent-macos-x64"
        ;;
    *)
        echo "[ERREUR] Architecture non supportee: $ARCH"
        exit 1
        ;;
esac

echo "[1/6] Architecture detectee: macOS-$ARCH -> $BINARY"

# 3. Creer le dossier
echo "[2/6] Creation du dossier $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# 4. Telecharger
echo "[3/6] Telechargement du binaire (version: $VERSION)..."
TMP_FILE="$(mktemp)"

if ! curl -fL --retry 3 -o "$TMP_FILE" "${GITHUB_URL}/${BINARY}"; then
    echo "[WARN] Echec GitHub Releases, fallback sur ${FALLBACK_URL}..."
    curl -fL --retry 3 -o "$TMP_FILE" "${FALLBACK_URL}/${BINARY}"
fi

mv "$TMP_FILE" "$INSTALL_DIR/print-agent"
chmod +x "$INSTALL_DIR/print-agent"

# 5. Gatekeeper : retirer le quarantine attr pour eviter le blocage si non-signe.
#    Binaire officiel : signe + notarise (Team ID 4Z5WZ89A6H) donc xattr -cr est defensif.
echo "[4/6] Configuration Gatekeeper..."
xattr -cr "$INSTALL_DIR/print-agent" 2>/dev/null || true

# 6. Config
echo "[5/6] Generation de la configuration..."
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    cat > "$INSTALL_DIR/config.json" << 'CONF'
{
  "apiUrl": "https://erp-pme-api.onrender.com/api/printing",
  "agentKey": "",
  "agentId": "",
  "agentName": "Agent macOS",
  "pollIntervalMinutes": 15,
  "snmpCommunity": "public",
  "snmpTimeout": 5000,
  "networkRange": "192.168.1.0/24",
  "printerIps": []
}
CONF
fi

# 7. LaunchDaemon
echo "[6/6] Installation LaunchDaemon..."
cat > "$LAUNCH_DAEMON" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.1acces.print-agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/print-agent</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/1acces-print-agent.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/1acces-print-agent.err.log</string>
</dict>
</plist>
EOF

chown root:wheel "$LAUNCH_DAEMON"
chmod 644 "$LAUNCH_DAEMON"

echo ""
echo "============================================="
echo "  Installation terminee !"
echo "============================================="
echo ""
echo "  1. Editez $INSTALL_DIR/config.json"
echo "     (renseignez agentKey et agentId generes sur erp.1acces.com)"
echo ""
echo "  2. Demarrez le service :"
echo "     sudo launchctl load $LAUNCH_DAEMON"
echo ""
echo "  3. Voir les logs :"
echo "     tail -f /var/log/1acces-print-agent.log"
echo ""
echo "  Pour arreter :"
echo "     sudo launchctl unload $LAUNCH_DAEMON"
echo ""
echo "============================================="
