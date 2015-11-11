#!/bin/bash
source /home/nobody/functions.sh
#
# Parses DHCP options from openvpn to update resolv.conf
# To use set as 'up' and 'down' script in your openvpn *.conf:
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf
#
# Used snippets of resolvconf script by Thomas Hood <jdthood@yahoo.co.uk>
# and Chris Hanson
# Licensed under the GNU GPL.  See /usr/share/common-licenses/GPL.
#
# 05/2006 chlauber@bnc.ch
#
# Example envs set from openvpn:
# foreign_option_1='dhcp-option DNS 193.43.27.132'
# foreign_option_2='dhcp-option DNS 193.43.27.133'
# foreign_option_3='dhcp-option DOMAIN be.bnc.ch'

[ -x /usr/sbin/resolvconf ] || exit 0

case $script_type in

up)
        for optionname in ${!foreign_option_*} ; do
                option="${!optionname}"
                echo $option
                part1=$(echo "$option" | cut -d " " -f 1)
                if [ "$part1" == "dhcp-option" ] ; then
                        part2=$(echo "$option" | cut -d " " -f 2)
                        part3=$(echo "$option" | cut -d " " -f 3)
                        if [ "$part2" == "DNS" ] ; then
                                IF_DNS_NAMESERVERS="$IF_DNS_NAMESERVERS $part3"
                        fi
                        if [ "$part2" == "DOMAIN" ] ; then
                                IF_DNS_SEARCH="$IF_DNS_SEARCH $part3"
                        fi
                fi
        done
        R=""
        for SS in $IF_DNS_SEARCH ; do
                R="${R}search $SS
"
        done
        for NS in $IF_DNS_NAMESERVERS ; do
                R="${R}nameserver $NS
"
        done
        echo -n "$R" | /usr/sbin/resolvconf -a "${dev}.inet"
        ;;
down)
        /usr/sbin/resolvconf -d "${dev}.inet"
        ;;
esac
