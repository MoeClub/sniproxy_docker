#!/bin/sh

ocVer="${1:-1.4.1}"
dnsVer="${2:-2.92}"

apk add wget iproute2 openssl iptables
sh /mnt/update.sh "${ocVer}" "${dnsVer}"
mkdir -p /etc/dnsmasq.d /etc/ocserv/group
[ -f /mnt/Default ] && cp -rf /mnt/Default /etc/ocserv/group
[ -f /mnt/NoRoute ] && cp -rf /mnt/NoRoute /etc/ocserv/group
[ -f /mnt/ocserv.conf ] && cp -rf /mnt/ocserv.conf /etc/ocserv
[ -f /mnt/p12.sh ] && cp -rf /mnt/p12.sh /etc/ocserv
[ -f /mnt/dnsmasq.conf ] && cp -rf /mnt/dnsmasq.conf /etc/dnsmasq.conf
[ -f /mnt/run.sh ] && cp -rf /mnt/run.sh /run.sh
chmod -R 777 /etc/dnsmasq.d /etc/dnsmasq.conf /etc/ocserv /run.sh
find /var -type f -delete
echo >$HOME/.ash_history
