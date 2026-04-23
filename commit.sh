#!/bin/sh

sniVer="${1:-0.7.0}"
dnsVer="${2:-2.92}"

apk add wget iproute2 openssl iptables
sh /mnt/update.sh "${sniVer}" "${dnsVer}"
mkdir -p /etc/sniproxy
[ -f /mnt/sniproxy.conf ] && cp -rf /mnt/sniproxy.conf /etc/sniproxy
[ -f /mnt/dnsmasq-lo.conf ] && cp -rf /mnt/dnsmasq-lo.conf /etc/sniproxy
[ -f /mnt/dnsmasq-up.conf ] && cp -rf /mnt/dnsmasq-up.conf /etc/sniproxy
[ -f /mnt/run.sh ] && cp -rf /mnt/run.sh /run.sh
chmod -R 777 /etc/sniproxy /run.sh
find /var -type f -delete
echo >$HOME/.ash_history
