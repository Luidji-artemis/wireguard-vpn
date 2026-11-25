# Configuration du client

La configuration du client est generee sur le serveur par add-client.sh dans /etc/wireguard/clients/<nom>.conf. Elle contient la cle privee du client : ne jamais la publier. Voir configs/client1.conf.example pour le modele.

## Client Linux (PC ou VM)

    sudo apt install -y wireguard
    sudo nano /etc/wireguard/wg0.conf     # coller la configuration du client
    sudo wg-quick up wg0
    sudo wg show

Arret : sudo wg-quick down wg0

## Client telephone (Android ou iOS)

1. Installer l'application WireGuard.
2. Generer le QR code sur le serveur : sudo QR=1 ./scripts/add-client.sh telephone <IP_SERVEUR>
3. Dans l'application : +, Creer a partir d'un code QR, puis activer le tunnel.

Le telephone doit pouvoir joindre l'IP du serveur sur le port UDP 51820.

## Client simule sur la meme machine (utilise pour ce TP)

Un espace de noms reseau joue le role d'une seconde machine.

    sudo ip netns add client1
    sudo ip link add veth-host type veth peer name veth-client
    sudo ip link set veth-client netns client1
    sudo ip addr add 192.168.100.1/24 dev veth-host
    sudo ip link set veth-host up
    sudo ip netns exec client1 ip addr add 192.168.100.2/24 dev veth-client
    sudo ip netns exec client1 ip link set veth-client up
    sudo ip netns exec client1 ip link set lo up
    sudo ip netns exec client1 ip route add default via 192.168.100.1
    sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o <INTERFACE_SORTIE> -j MASQUERADE
    sudo iptables -I FORWARD -i veth-host -j ACCEPT
    sudo iptables -I FORWARD -o veth-host -j ACCEPT
    sudo mkdir -p /etc/netns/client1
    echo "nameserver 1.1.1.1" | sudo tee /etc/netns/client1/resolv.conf

Le client doit etre cree avec l'endpoint 192.168.100.1 :

    sudo ./scripts/add-client.sh client1 192.168.100.1
    sudo bash -c 'umask 077; sed "/^DNS/d" /etc/wireguard/clients/client1.conf > /tmp/client1-ns.conf'
    sudo ip netns exec client1 ip link add wgc type wireguard
    sudo ip netns exec client1 wg setconf wgc /dev/stdin <<< "$(sudo wg-quick strip /tmp/client1-ns.conf)"
    sudo ip netns exec client1 ip addr add 10.8.0.2/24 dev wgc
    sudo ip netns exec client1 ip link set wgc up
    sudo ip netns exec client1 ip route add 192.168.100.1 dev veth-client
    sudo ip netns exec client1 ip route replace default dev wgc

Nettoyage :

    sudo ip netns del client1
    sudo rm -f /tmp/client1-ns.conf
