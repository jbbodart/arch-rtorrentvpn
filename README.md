Arch Linux : rtorrent + OpenVPN + Privoxy
=========================================

arch linux : https://www.archlinux.org/

rtorrent : https://github.com/rakshasa/rtorrent

rutorrent : https://github.com/Novik/ruTorrent

openvpn : https://openvpn.net/

privoxy : http://www.privoxy.org/

**Description**

Latest stable rtorrent release for Arch Linux, including OpenVPN
to tunnel torrent traffic securely (using iptables to block any
traffic not bound for tunnel).

ruTorrent v3.7 included for rtorrent GUI.

This also includes Privoxy to allow unfiltered http|https traffic through the VPN.

**Usage**
```
docker run -d \
	--cap-add=NET_ADMIN \
	-p 8080:8080 \
	-p 8118:8118 \
	-p 2222:2222 \
	--name=<container name> \
	-v <path for data files>:/data \
	-v <path for config files>:/config \
	-e LOCAL_LAN=<local network in CIDR notation> \
	-e ENABLE_VPN=<yes|no> \
	-e ENABLE_PRIVOXY=<yes|no> \
	-e ENABLE_SSHD=<yes|no> \
	-e RTORRENT_LISTEN_PORT=<port no> \	
	-e RTORRENT_DHT_PORT=<port no> \		
	jbbodart/arch-rtorrentvpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access ruTorrent**

`http://<host ip>:8080`

**Access Privoxy**

`http://<host ip>:8118`

**SSH to docker**

`ssh -p 2222 root@<host ip>`

No password required.

**Setting up VPN**

1. Start the rtorrentvpn docker to create the folder structure
2. Stop rtorrentvpn docker and copy your .ovpn file in the /config/openvpn/ folder on the host
3. Start rtorrentvpn docker

**Execute in Docker on Synology**

1. Before running this container, you must make sure that mandatory kernel modules are loaded.
SSH as root to your Sylology NAS and insmod the following modules :
```
insmod /lib/modules/tun.ko
insmod /lib/modules/iptable_mangle.ko
insmod /lib/modules/xt_mark.ko
```
2. Download container image by searching jbbodart/rtorrentvpn on Docker Hub Registry
3. Create a directory for the container data (eg /docker/data and /docker/config)
4. Launch container with "Docker Run" command. For exemple :
```
docker run -d -p 8112:8112 -p 8118:8118 -p 2222:2222 --name=rtorrentvpn -v /docker/data:/data -v /docker/config:/config -e ENABLE_VPN=yes -e ENABLE_PRIVOXY=yes -e ENABLE_SSHD=yes -e RTORRENT_LISTEN_PORT=49314 -e RTORRENT_DHT_PORT=49313 jbbodart/arch-rtorrentvpn
```
5. Synology Docker GUI does not support "--cap-add=NET_ADMIN" option. Plese go to "Advanced Setting" -> "Environnement" and check "Using high privilege execute container"
6. Stop container and copy your .ovpn file in the /docker/DelugeVPN/config/openvpn/ folder
7. Restart container

**Using the container**

To start downloading, place a .torrent file in the /data/watch directory.

Completed downloads are stored in /data/downloads.

**Advanced configuration**

Config files for rtorrent, rutorrent, openvpn, privoxy and nginx are located in the /config directory and can be modified (may need to restart the container).

