#!/bin/sh

if [ ! -f "/.initialized" ]; then
  [ -n "${TZ}" ] && [ -e "/usr/share/zoneinfo/${TZ}" ] && cp -rf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  device=`printenv DEVICE`
  [ -n "$device" ] || device=`ls -1 /sys/class/net| grep -v '^lo$' |head -n 1`
  [ -n "$device" ] || exit 1
  addr=`printenv ADDR`
  [ -n "$addr" ] || addr=`wget -qO- -T 3 https://checkip.amazonaws.com/`
  [ -n "$addr" ] || addr=`ip -4 addr show "$device" | awk '/inet /{print $2}' | cut -d/ -f1`
  udns=`printenv UDNS`
  [ -n "$udns" ] || udns="8.8.4.4"
  uport=`printenv UPORT`
  [ -n "$uport" ] || uport="53"
  echo "DNS: ${udns}:${uport}"
  port=`printenv PORT`
  [ -n "$port" ] || port="53"
  echo "Public: ${addr}:${port}"
  fallback=`printenv FALLBACK`
  [ "$fallback" == "0" ] || fallback="1"
  if [ -f /etc/sniproxy/sniproxy.conf ]; then
    for item in `printenv "TABLE" |sed 's/;/\n/g'`; do
      echo "${item}" |grep -q "," || continue
      src="${item%%,*}"
      dst="${item#*,}"
      [ -n "$dst" ] || dst="*"
      target="${src//./\\.}\$ ${dst}"
      echo "${target}" | grep -q '^\*'
      if [ "$?" -eq "0" ]; then
        line0="^.${target//\\/\\\\}"
        line1=""
      else
        line0="^${target//\\/\\\\}"
        line1="^.*\\\\.${target//\\/\\\\}"
      fi
      [ -n "$line1" ] && sed -i "/\.\*\ \*/i\ \ \ \ ${line1}" /etc/sniproxy/sniproxy.conf
      [ -n "$line0" ] && sed -i "/\.\*\ \*/i\ \ \ \ ${line0}" /etc/sniproxy/sniproxy.conf
      if [ -f "/etc/sniproxy/dnsmasq-lo.conf" ]; then
        [ "${dst}" != "*" ] && echo "${src}" |grep -q "\." && tbl=`echo "${src}" |sed 's/^\*//' |sed 's/^\.//' |sed 's/\.$//'` && echo "server=/${tbl}/${udns}#${uport}" >>"/etc/sniproxy/dnsmasq-lo.conf"
      fi
    done
    if [ "$fallback" != "1" ]; then
      sed -i "/\.\*\ \*/d" /etc/sniproxy/sniproxy.conf
    fi
  fi
  if [ -f /etc/sniproxy/dnsmasq-up.conf ]; then
    sed -i "s/^server=.*/server=${udns}#${uport}/" "/etc/sniproxy/dnsmasq-up.conf"
  fi

  if [ -f /etc/sniproxy/dnsmasq-lo.conf ]; then
    sed -i "s/^interface=.*/interface=${device}/" "/etc/sniproxy/dnsmasq-lo.conf"
    sed -i "s/^port=.*/port=${port}/" "/etc/sniproxy/dnsmasq-lo.conf"
    sed -i "s/^address=.*/address=\/#\/${addr}/" "/etc/sniproxy/dnsmasq-lo.conf"
    for item in `printenv "DNS" |sed 's/;/\n/g'`; do
      echo "${item}" |grep -q "\." && echo "server=/${item}/${udns}#${uport}" >>"/etc/sniproxy/dnsmasq-lo.conf"
    done
  fi

fi

touch "/.initialized"

/usr/sbin/dnsmasq -v
[ -f /etc/sniproxy/dnsmasq-up.conf ] && /usr/sbin/dnsmasq -C /etc/sniproxy/dnsmasq-up.conf
[ -f /etc/sniproxy/dnsmasq-lo.conf ] && /usr/sbin/dnsmasq -C /etc/sniproxy/dnsmasq-lo.conf

/usr/sbin/sniproxy -V
exec /usr/sbin/sniproxy -c /etc/sniproxy/sniproxy.conf -f
