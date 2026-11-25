#!/usr/bin/env bash
# revoke-client.sh : revoque un client WireGuard (supprime son acces et ses cles)
# Usage : sudo ./revoke-client.sh <nom>
set -euo pipefail

WG_IF="${WG_IF:-wg0}"
WG_DIR="/etc/wireguard"
CONF="${WG_DIR}/${WG_IF}.conf"

if [[ $EUID -ne 0 ]]; then
  echo "Erreur : lancer avec sudo" >&2
  exit 1
fi

NAME="${1:-}"
if [[ ! "${NAME}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Usage : sudo $0 <nom>" >&2
  exit 1
fi

if ! grep -q "^# client: ${NAME}$" "${CONF}"; then
  echo "Erreur : client ${NAME} introuvable" >&2
  exit 1
fi

# Sauvegarde avant modification
cp "${CONF}" "${CONF}.bak"

# On retire le bloc [Peer] du client (mode paragraphe d'awk)
TMP=$(mktemp)
awk -v RS="" -v ORS="\n\n" -v n="${NAME}" '$0 !~ ("# client: " n "(\n|$)")' "${CONF}" > "${TMP}"
install -m 600 "${TMP}" "${CONF}"
rm -f "${TMP}"

# Application a chaud : le pair disparait de l'interface
wg syncconf "${WG_IF}" <(wg-quick strip "${WG_IF}")

# Suppression de la config client
rm -f "${WG_DIR}/clients/${NAME}.conf"
echo "Client ${NAME} revoque."
wg show "${WG_IF}"
