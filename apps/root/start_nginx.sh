#!/bin/bash
source /home/nobody/functions.sh

/usr/bin/nginx -g "daemon off;" -c /config/nginx/nginx.conf
