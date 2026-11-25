# Architecture

## Schema

    +---------------------+        tunnel WireGuard (UDP 51820)        +---------------------------+
    |  Client             |  <=======================================> |  Serveur VPN (Ubuntu)     |
    |  wgc  10.8.0.2/24   |        paquets chiffres (ChaCha20)         |  wg0  10.8.0.1/24         |
    +---------------------+                                            |  NAT (MASQUERADE)         |
                                                                       +-------------+-------------+
                                                                                     |
                                                                                  Internet

## Parametres

| Element              | Valeur          |
|----------------------|-----------------|
| Reseau du VPN        | 10.8.0.0/24     |
| Adresse du serveur   | 10.8.0.1        |
| Adresses des clients | 10.8.0.2 et plus|
| Port                 | 51820/udp       |
| Routage client       | 0.0.0.0/0 (tout le trafic passe par le VPN) |
| DNS client           | 1.1.1.1         |

## Fonctionnement

1. Chaque machine possede une paire de cles (privee, publique). Seules les cles publiques sont echangees.
2. Le serveur declare chaque client par sa cle publique et lui reserve une adresse /32.
3. Le client envoie ses paquets chiffres vers le serveur. Le serveur les dechiffre, les transmet a Internet et applique le NAT (MASQUERADE) pour renvoyer les reponses.
4. Le routage IPv4 est active sur le serveur (net.ipv4.ip_forward=1).

## Environnement de test

Le client est simule sur la meme machine que le serveur grace a un espace de noms reseau (ip netns), relie au serveur par une paire veth (192.168.100.0/24). Voir tests.md pour les limites de ce montage.
