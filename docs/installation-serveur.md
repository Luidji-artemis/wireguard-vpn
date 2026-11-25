# Installation du serveur

## Prerequis

- Ubuntu ou Debian, acces sudo
- Port UDP 51820 joignable depuis le client (pare-feu, box ou fournisseur cloud)

## Installation automatique

    git clone https://github.com/Luidji-artemis/wireguard-vpn
    cd wireguard-vpn
    sudo ./scripts/install-wireguard.sh

Le script :

1. installe wireguard, iptables et qrencode ;
2. detecte l'interface de sortie vers Internet ;
3. genere les cles du serveur dans /etc/wireguard (droits 600) ;
4. ecrit /etc/wireguard/wg0.conf avec le NAT ;
5. active le routage IPv4 de facon persistante ;
6. ouvre le port 51820/udp si ufw est actif ;
7. demarre et active wg-quick@wg0 au demarrage.

Variables optionnelles : WG_IF, WG_PORT, WG_ADDR.

## Verification

    sudo wg show
    sudo systemctl status wg-quick@wg0
    sysctl net.ipv4.ip_forward

wg show doit afficher interface: wg0 et le port 51820.

## Gestion des clients

Ajouter un client (l'IP ou le nom de domaine du serveur est le deuxieme argument) :

    sudo ./scripts/add-client.sh telephone <IP_SERVEUR>

Afficher un QR code pour un telephone :

    sudo QR=1 ./scripts/add-client.sh telephone <IP_SERVEUR>

Revoquer un client :

    sudo ./scripts/revoke-client.sh telephone

## Installation manuelle

Les etapes du script peuvent etre faites a la main : voir configs/wg0.conf.example pour le fichier de configuration.

## Problemes rencontres

- apt update peut echouer a cause de depots tiers casses : le script continue.
- Plusieurs routes par defaut : l'interface est choisie avec ip route get 1.1.1.1.
