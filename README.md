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
Also includes Privoxy to allow http|https traffic through the VPN.

This container has been designed to work on Synology devices, but it should run on every Linux host
(tun kernel module and iptables required for VPN).
Tested with DSM 6.0.1-7393 Update 2.

**Usage**
```
docker run -d \
	--cap-add=NET_ADMIN \
	-p 8080:8080 \
	-p 8118:8118 \
	--name=<container name> \
	-v <path for data files>:/data \
	-v <path for config files>:/config \
	-e ENABLE_VPN=<yes|no> \
	-e ENABLE_PRIVOXY=<yes|no> \
	-e RTORRENT_LISTEN_PORT=<port no> \	
	-e RTORRENT_DHT_PORT=<port no> \		
	jbbodart/arch-rtorrentvpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access ruTorrent**

`http://<host ip>:8080`

**Access Privoxy**

`http://<host ip>:8118`

**Setting up VPN**

1. Start the rtorrentvpn docker to create the folder structure
2. Stop rtorrentvpn docker and copy your .ovpn file in the /config/openvpn/ folder on the host
3. Start rtorrentvpn docker

**Execute in Docker on Synology**

1. Create a directory for the container data (eg /docker/data and /docker/config)
2. Start Synology Docker GUI
3. Download container image by searching jbbodart/rtorrentvpn on Docker Hub Registry
4. Create a new container using this image. You need to check the "Execute container using high privilege" box for iptables to work. 
6. Start container to populate the config directory
7. Stop container and copy your .ovpn file in the /docker/config/openvpn/ folder
8. Restart container

**Using the container**

To start downloading, place a .torrent file in the /data/watch directory.

Completed downloads are stored in /data/downloads.

**Advanced configuration**

Config files for rtorrent, rutorrent, openvpn, privoxy and nginx are located in the /config directory and can be modified (may need to restart the container).

