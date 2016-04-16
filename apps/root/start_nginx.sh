#!/bin/bash
source /home/nobody/functions.sh

# ugly hack for DSM6
cp -a /usr/bin/nginx /usr/local/bin/nginx
/usr/local/bin/nginx -g "daemon off;" -c /config/nginx/nginx.conf
