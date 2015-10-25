#!/bin/bash

echo "[info] waiting for rtorrent to start up..."

# wait for rtorrent responding on the xmlrpc interface
until $(xmlrpc http://localhost:8080/RPC2 get_bind > /dev/null 2>&1); do
	sleep 1
done

echo "[info] rtorrent started, starting configuration"

if [[ "${RTORRENT_LISTEN_PORT}" =~ ^-?[0-9]+$ ]]; then
	echo "[info] configuring rtorrent listen port..."
	# enable bind incoming port to specific port (disable random)
	xmlrpc http://localhost:8080/RPC2 set_port_random i/0
	# set incoming port
	xmlrpc http://localhost:8080/RPC2 set_port_range "${RTORRENT_LISTEN_PORT}-${RTORRENT_LISTEN_PORT}"
fi

if [[ "${RTORRENT_DHT_LISTEN_PORT}" =~ ^-?[0-9]+$ ]]; then
	echo "[info] configuring rtorrent dht listen port..."
	# set dht port
	xmlrpc http://localhost:8080/RPC2 set_dht_port "${RTORRENT_DHT_LISTEN_PORT}"
fi

echo "[info] rtorrent configuration completed"




