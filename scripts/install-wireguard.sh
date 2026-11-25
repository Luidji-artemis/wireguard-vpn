#!/usr/bin/env bash
# install-wireguard.sh : installe et configure un serveur WireGuard (Debian/Ubuntu)
# Usage : sudo ./install-wireguard.sh
# Variables optionnelles : WG_IF (wg0), WG_PORT (51820), WG_ADDR (10.8.0.1/24)
set -euo pipefail

WG_IF="${WG_IF:-wg0}"
WG_PORT="${WG_PORT:-51820}"
WG_ADDR="${WG_ADDR:-10.8.0.1/24}"
WG_DIR="/etc/wireguard"

# Le script doit tourner en root
if [[ $EUID -ne 0 ]]; then
  echo "Erreur : lancer avec sudo" >&2
  exit 1
fi

# On refuse d'ecraser une configuration existante
if [[ -f "${WG_DIR}/${WG_IF}.conf" ]]; then
  echo "Erreur : ${WG_DIR}/${WG_IF}.conf existe deja" >&2
  exit 1
fi

# 1. Installation des paquets
apt-get update || echo "Avertissement : apt update a echoue (depots tiers), on continue"
apt-get install -y wireguard iptables qrencode

# 2. Interface de sortie vers Internet (celle utilisee pour joindre 1.1.1.1)
OUT_IF=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
echo "Interface de sortie : ${OUT_IF}"

# 3. Cles du serveur (droits 600 : umask 077)
umask 077
mkdir -p "${WG_DIR}/clients"
wg genkey | tee "${WG_DIR}/server_private.key" | wg pubkey > "${WG_DIR}/server_public.key"
PRIV=$(cat "${WG_DIR}/server_private.key")

# 4. Fichier de configuration : NAT et forwarding actives au demarrage du tunnel
cat > "${WG_DIR}/${WG_IF}.conf" <<EOF
[Interface]
Address = ${WG_ADDR}
ListenPort = ${WG_PORT}
PrivateKey = ${PRIV}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${OUT_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${OUT_IF} -j MASQUERADE
EOF
chmod 600 "${WG_DIR}/${WG_IF}.conf"

# 5. Activation du routage IPv4 (persistant)
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
sysctl --system > /dev/null

# 6. Ouverture du port si ufw est actif
if command -v ufw > /dev/null && ufw status | grep -q "Status: active"; then
  ufw allow "${WG_PORT}/udp"
fi

# 7. Demarrage et activation au boot
systemctl enable "wg-quick@${WG_IF}"
systemctl restart "wg-quick@${WG_IF}"
echo "Serveur WireGuard pret. Cle publique : $(cat "${WG_DIR}/server_public.key")"
wg show "${WG_IF}"
