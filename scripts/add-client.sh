#!/usr/bin/env bash
# add-client.sh : ajoute un client WireGuard et genere sa configuration
# Usage : sudo ./add-client.sh <nom> [endpoint_serveur]
# Exemple : sudo ./add-client.sh telephone 203.0.113.10
# Variables optionnelles : WG_IF (wg0), WG_PORT (51820), QR=1 (affiche un QR code)
set -euo pipefail

WG_IF="${WG_IF:-wg0}"
WG_PORT="${WG_PORT:-51820}"
WG_DIR="/etc/wireguard"
CONF="${WG_DIR}/${WG_IF}.conf"

if [[ $EUID -ne 0 ]]; then
  echo "Erreur : lancer avec sudo" >&2
  exit 1
fi

[[ -f "${CONF}" ]] || { echo "Erreur : serveur non installe (lancer install-wireguard.sh)" >&2; exit 1; }
NAME="${1:-}"
ENDPOINT="${2:-${SERVER_ENDPOINT:-}}"

# Le nom ne doit contenir que des caracteres simples
if [[ ! "${NAME}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Usage : sudo $0 <nom> [endpoint_serveur]" >&2
  exit 1
fi

# Sans endpoint fourni, on prend l'IP locale de l'interface de sortie
if [[ -z "${ENDPOINT}" ]]; then
  OUT_IF=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
  ENDPOINT=$(ip -4 -o addr show "${OUT_IF}" | awk '{print $4}' | cut -d/ -f1)
  echo "Attention : endpoint deduit automatiquement (${ENDPOINT})"
fi

# Le client ne doit pas deja exister
if grep -q "^# client: ${NAME}$" "${CONF}"; then
  echo "Erreur : le client ${NAME} existe deja" >&2
  exit 1
fi

# Premiere adresse libre dans 10.8.0.0/24 (.1 est le serveur)
NEXT=""
for i in $(seq 2 254); do
  if ! grep -q "AllowedIPs = 10.8.0.${i}/32" "${CONF}"; then
    NEXT="10.8.0.${i}"
    break
  fi
done
if [[ -z "${NEXT}" ]]; then
  echo "Erreur : plus d'adresse disponible" >&2
  exit 1
fi

# Cles du client
umask 077
mkdir -p "${WG_DIR}/clients"
CPRIV=$(wg genkey)
CPUB=$(echo "${CPRIV}" | wg pubkey)
SPUB=$(cat "${WG_DIR}/server_public.key")

# Declaration du client cote serveur
cat >> "${CONF}" <<EOF

[Peer]
# client: ${NAME}
PublicKey = ${CPUB}
AllowedIPs = ${NEXT}/32
EOF

# Application a chaud, sans couper les autres clients
wg syncconf "${WG_IF}" <(wg-quick strip "${WG_IF}")

# Configuration a donner au client
cat > "${WG_DIR}/clients/${NAME}.conf" <<EOF
[Interface]
PrivateKey = ${CPRIV}
Address = ${NEXT}/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${SPUB}
Endpoint = ${ENDPOINT}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "Client ${NAME} cree : ${NEXT}"
echo "Configuration : ${WG_DIR}/clients/${NAME}.conf"
if [[ "${QR:-0}" == "1" ]]; then
  qrencode -t ansiutf8 < "${WG_DIR}/clients/${NAME}.conf"
fi
