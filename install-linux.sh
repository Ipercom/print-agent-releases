#!/bin/bash
# =============================================
#   1Acces Print Collector Agent - Installation (Linux)
# =============================================
# Auto-detecte l'architecture et telecharge le binaire depuis GitHub Releases.
# Fallback : https://erp.1acces.com/downloads/
# =============================================

set -e

echo "============================================="
echo "  1Acces Print Collector Agent - Installation"
echo "============================================="
echo ""

# 1. Verifier root
if [ "$EUID" -ne 0 ]; then
    echo "[ERREUR] Veuillez executer ce script en tant que root (sudo)"
    exit 1
fi

INSTALL_DIR="/opt/1acces/print-agent"
VERSION="${PRINT_AGENT_VERSION:-latest}"

GITHUB_BASE="https://github.com/Ipercom/print-agent-releases/releases"
if [ "$VERSION" = "latest" ]; then
    GITHUB_URL="${GITHUB_BASE}/latest/download"
else
    GITHUB_URL="${GITHUB_BASE}/download/${VERSION}"
fi
FALLBACK_URL="https://erp.1acces.com/downloads"

# 2. Detecter l'architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS-$ARCH" in
    linux-x86_64|linux-amd64)
        BINARY="print-agent-linux-x64"
        ;;
    linux-aarch64|linux-arm64)
        BINARY="print-agent-linux-arm64"
        ;;
    *)
        echo "[ERREUR] Architecture non supportee: $OS-$ARCH"
        echo "         Architectures supportees: linux-x86_64, linux-aarch64"
        exit 1
        ;;
esac

echo "[1/6] Architecture detectee: $OS-$ARCH -> $BINARY"

# 3. Creer le dossier
echo "[2/6] Creation du dossier $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# 4. Telecharger le binaire
echo "[3/6] Telechargement du binaire (version: $VERSION)..."
TMP_FILE="$(mktemp)"

download() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 -o "$TMP_FILE" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$TMP_FILE" "$url"
    else
        echo "[ERREUR] curl ou wget requis pour telecharger"
        exit 1
    fi
}

if ! download "${GITHUB_URL}/${BINARY}"; then
    echo "[WARN] Echec GitHub Releases, fallback sur ${FALLBACK_URL}..."
    download "${FALLBACK_URL}/${BINARY}"
fi

mv "$TMP_FILE" "$INSTALL_DIR/print-agent"
chmod +x "$INSTALL_DIR/print-agent"

# 5. Generer config
echo "[4/6] Generation de la configuration..."
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    cat > "$INSTALL_DIR/config.json" << 'CONF'
{
  "apiUrl": "https://erp-pme-api.onrender.com/api/printing",
  "agentKey": "",
  "agentId": "",
  "agentName": "Agent Linux",
  "pollIntervalMinutes": 15,
  "snmpCommunity": "public",
  "snmpTimeout": 5000,
  "networkRange": "192.168.1.0/24",
  "printerIps": []
}
CONF
fi

# 6. Creer le service systemd
echo "[5/6] Installation du service systemd..."
cat > /etc/systemd/system/1acces-print-agent.service << EOF
[Unit]
Description=1Acces Print Collector Agent
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/print-agent
Restart=always
RestartSec=30
User=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable 1acces-print-agent

# 7. Afficher les instructions
echo "[6/6] Installation terminee !"
echo ""
echo "============================================="
echo "  CONFIGURATION REQUISE"
echo "============================================="
echo ""
echo "  1. Ouvrez https://erp.1acces.com"
echo "  2. Gestion Impression > Agents > Nouvel agent"
echo "  3. Copiez l'Agent ID et l'Agent Key"
echo "  4. Editez $INSTALL_DIR/config.json"
echo "     sudo nano $INSTALL_DIR/config.json"
echo "  5. Collez agentKey et agentId"
echo "  6. Demarrez le service :"
echo "     sudo systemctl start 1acces-print-agent"
echo ""
echo "  Commandes utiles :"
echo "     sudo systemctl status 1acces-print-agent"
echo "     sudo journalctl -u 1acces-print-agent -f"
echo ""
echo "============================================="
