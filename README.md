Deluge + OpenVPN + Privoxy
==========================

Deluge - http://deluge-torrent.org/
OpenVPN - https://openvpn.net/
Privoxy - http://www.privoxy.org/

Latest stable Deluge release for Arch Linux, including OpenVPN to tunnel torrent traffic securely (using iptables to block any traffic not bound for tunnel). This now also includes Privoxy to allow unfiltered http|https traffic via VPN.

**Pull image**

```
docker pull jbbodart/arch-delugevpn
```

**Run container**


```
docker run -d --cap-add=NET_ADMIN -p 8112:8112 -p 8118:8118 -p 2222:2222 --name=<container name> -v <path for data files>:/data -v <path for config files>:/config -e ENABLE_VPN=<yes|no> -e ENABLE_PRIVOXY=<yes|no> -e ENABLE_SSHD=<yes|no> -e DELUGE_LISTEN_PORT=<port no> jbbodart/arch-delugevpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access Deluge**

```
http://<host ip>:8112
```

Default password for the webui is "deluge"

**Access Privoxy**

```
<host ip>:8118
```

Default is no authentication required

**Access inside container with SSH**

```
ssh -p 2222 root@<host ip>
```

No password required

**OpenVPN Setup**

1. Start the delugevpn docker to create the folder structure
2. Stop delugevpn docker and copy your .ovpn file in the /config/openvpn/ folder on the host
3. Start delugevpn docker
4. Check supervisor.log to make sure you are connected to the tunnel

*Example*

```
docker run -d --cap-add=NET_ADMIN -p 8112:8112 -p 8118:8118 -p 2222:2222 --name=DelugeVPN -v /docker/DelugeVPN/data:/data -v /docker/DelugeVPN/config:/config -e ENABLE_VPN=yes -e ENABLE_PRIVOXY=yes -e ENABLE_SSHD=yes -e DELUGE_LISTEN_PORT=49313 jbbodart/arch-delugevpn
```

**Execute in Docker on Synology**

1. Before running this container, you must make sure that mandatory kernel modules are loaded.
SSH as root to your Sylology NAS and insmod the following modules :
```
insmod /lib/modules/tun.ko
insmod /lib/modules/iptable_mangle.ko
insmod /lib/modules/xt_mark.ko
```
2. Download container image by searching jbbodart/delugevpn on Docker Hub Registry
3. Create a directory for the container data (eg /docker/DelugeVPN)
4. Launch container with "Docker Run" command. For exemple :
```
docker run -d -p 8112:8112 -p 8118:8118 -p 2222:2222 --name=DelugeVPN -v /docker/DelugeVPN/data:/data -v /docker/DelugeVPN/config:/config -e ENABLE_VPN=yes -e ENABLE_PRIVOXY=yes -e ENABLE_SSHD=yes -e DELUGE_LISTEN_PORT=49313 jbbodart/arch-delugevpn
```
5. Synology Docker GUI does not support "--cap-add=NET_ADMIN" option. Plese go to "Advanced Setting" -> "Environnement" and check "Using high privilege execute container"
6. Stop container and copy your .ovpn file in the /docker/DelugeVPN/config/openvpn/ folder
7. Restart container
