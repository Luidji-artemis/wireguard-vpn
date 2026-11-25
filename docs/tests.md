# Tests et preuves

Tous les tests sont lances depuis le client (prefixe sudo ip netns exec client1 pour le client simule).

## 1. Handshake

    sudo wg show

Attendu : une ligne latest handshake et un compteur transfer non nul sous le peer.
Preuve : screenshots/01-wg-show-serveur.png

## 2. IP publique vue par le client

    sudo ip netns exec client1 curl -s ifconfig.me
    curl -s ifconfig.me

Preuve : screenshots/02-curl-ifconfig-client.png

Limite : le client simule et le serveur sortent par la meme connexion, donc les deux IP sont identiques. Avec un serveur distant (VPS) ou un vrai client sur un autre reseau, l'IP du client doit devenir celle du serveur.

## 3. Ping et routage

    sudo ip netns exec client1 ping -c 4 10.8.0.1
    sudo ip netns exec client1 ping -c 4 1.1.1.1
    sudo ip netns exec client1 traceroute -n -m 3 1.1.1.1

Attendu : 0 % de perte, et 10.8.0.1 comme premier saut du traceroute, ce qui prouve que le trafic passe par le serveur VPN.
Preuve : screenshots/03-tests-ping.png

## 4. Trafic dans le tunnel

    sudo tcpdump -ni wg0 icmp

Pendant un ping du client vers 1.1.1.1, les requetes et reponses ICMP entre 10.8.0.2 et 1.1.1.1 apparaissent sur wg0.

## 5. Revocation

    sudo ./scripts/add-client.sh temp1 192.168.100.1
    sudo ./scripts/revoke-client.sh temp1
    sudo wg show | grep -c "^peer"

Attendu : le nombre de peers revient a sa valeur initiale, le fichier clients/temp1.conf est supprime et client1 continue de fonctionner.

## Resultats

| Test              | Resultat |
|-------------------|----------|
| Handshake         | OK       |
| Ping 10.8.0.1     | OK, 0 % de perte |
| Ping 1.1.1.1      | OK, 0 % de perte |
| Traceroute        | 1er saut 10.8.0.1 |
| DNS dans le tunnel| OK (ping google.com) |
| Revocation        | OK       |
