#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -n "$1" ]; then
    NEW_PASS="$1"
elif [ -f .env ]; then
    NEW_PASS=$(grep -E '^CEZAR_PASSWORD=' .env | cut -d '=' -f2-)
fi

if [ -z "$NEW_PASS" ]; then
    echo "❌ Błąd: Podaj nowe hasło jako argument: ./update-password.sh <haslo>"
    exit 1
fi

USER=$(grep -E '^CEZAR_USER=' .env | cut -d '=' -f2- || echo "tkogut")
USER="${USER:-tkogut}"

RAW_HASH=$(openssl passwd -apr1 "$NEW_PASS")
ESCAPED_HASH=$(echo "$RAW_HASH" | sed 's/\$/\$\$/g')

sed -i "s|^CEZAR_PASSWORD=.*|CEZAR_PASSWORD=${NEW_PASS}|" .env
sed -i "s|^CEZAR_BASIC_AUTH=.*|CEZAR_BASIC_AUTH=${USER}:${ESCAPED_HASH}|" .env

echo "🔄 Przeładowywanie konfiguracji Traefik..."
docker compose up -d

echo "✅ Hasło zaktualizowane pomyślnie dla użytkownika '$USER'."
echo "🌐 URL: https://cezar.srv1490214.hstgr.cloud"
