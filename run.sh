#!/bin/sh

[ -n "${TZ}" ] && [ -e "/usr/share/zoneinfo/${TZ}" ] && cp -rf "/usr/share/zoneinfo/${TZ}" /etc/localtime
device=`ls -1 /sys/class/net| grep -v '^lo$' |head -n 1`
[ -n "$device" ] || exit 1
addr=`printenv ADDR`
[ -n "$addr" ] || addr=`wget -qO- https://checkip.amazonaws.com/`
[ -n "$addr" ] || addr=`ip -4 addr show "$net" | awk '/inet /{print $2}' | cut -d/ -f1`
[ -n "$addr" ] && echo "Addr: ${addr}"
udns=`printenv UDNS`
[ -n "$udns" ] || udns="8.8.4.4"
uport=`printenv UPROT`
[ -n "$uport" ] || uport="53"
echo "DNS: ${udns}:${uport}"
port=`printenv PORT`
[ -n "$port" ] || port="53"
echo "Public: ${addr}:${port}"


/usr/sbin/sniproxy -V
if [ -f /etc/sniproxy/sniproxy.conf ]; then
  for item in `printenv "TABLE" |sed 's/;;/\n/g'`; do
    echo "${item}" |grep -q ";" || continue
    src="${item%%;*}"
    dst="${item#*;}"
    tagret="${src//./\\.} $dst"
    echo "${tagret}" | grep -q '^*' && line=".${tagret//\\/\\\\}" || line="${tagret//\\/\\\\}"
    sed -i "/\.\*\ \*/i\ \ \ \ ${line}" /etc/sniproxy/sniproxy.conf
    if [ -f "/etc/sniproxy/dnsmasq-lo.conf" ]; then
      echo "${src}" |grep -q "\." && tbl=`echo "${src}" |sed 's/^\*//' |sed 's/^\.//' |sed 's/\.$//'` && echo "server=/${tbl}/${udns}#${uport}" >>"/etc/sniproxy/dnsmasq-lo.conf"
    fi
  done
fi

/usr/sbin/dnsmasq -v
if [ -f /etc/sniproxy/dnsmasq-up.conf ]; then
  sed -i "s/^server=.*/server=${udns}#${uport}/" "/etc/sniproxy/dnsmasq-up.conf"
  /usr/sbin/dnsmasq -C /etc/sniproxy/dnsmasq-up.conf
fi
if [ -f /etc/sniproxy/dnsmasq-lo.conf ]; then
  sed -i "s/^interface=.*/interface=${device}/" "/etc/sniproxy/dnsmasq-lo.conf"
  sed -i "s/^port=.*/port=${port}/" "/etc/sniproxy/dnsmasq-lo.conf"
  sed -i "s/^address=.*/address=\/#\/${addr}/" "/etc/sniproxy/dnsmasq-lo.conf"

  for item in `printenv "DNS" |sed 's/;/\n/g'`; do
    echo "${item}" |grep -q "\." && echo "server=/${item}/${udns}#${uport}" >>"/etc/sniproxy/dnsmasq-lo.conf"
  done

  /usr/sbin/dnsmasq -C /etc/sniproxy/dnsmasq-lo.conf
fi


/usr/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f
