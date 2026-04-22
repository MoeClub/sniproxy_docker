#!/bin/sh

sVer="${1:-0}"
dVer="${2:-0}"
EndPoint="https://github.com/MoeClub/Note/raw/refs/heads/master/AnyConnect/build"

case `uname -m` in aarch64|arm64) arch="aarch64";; x86_64|amd64) arch="x86_64";; *) arch="";; esac
[ -n "$arch" ] || exit 1

if [ "$sVer" != "0" ]; then
  sniFile="sniproxy_${arch}_v${sVer}.tar.gz"
  [ -f "./${sniFile}" ] || {
    wget -qO "${sniFile}" "${EndPoint}/sniproxy_${arch}_v${sVer}.tar.gz"
    trapFile="${sniFile}"
    trap "rm -rf ${trapFile}" EXIT
    [ $? -eq 0 ] || exit 1
  }

  rm -rf /etc/sniproxy.conf
  rm -rf /usr/sbin/sniproxy
  rm -rf /usr/share/man/man5/sniproxy.conf.5
  rm -rf /usr/share/man/man8/sniproxy.8

  tar --overwrite -xvf "${sniFile}" -C /

  sniproxy -V
fi

if [ "$dVer" != "0" ]; then
  dnsmasqFile="dnsmasq_${arch}_v${dVer}.tar.gz"
  [ -f "./${dnsmasqFile}" ] || {
    wget -qO "${dnsmasqFile}" "${EndPoint}/dnsmasq_${arch}_v${dVer}.tar.gz"
    trapFile="${trapFile} ${dnsmasqFile}"
    trap "rm -rf ${trapFile}" EXIT
    [ $? -eq 0 ] || exit 1
  }

  rm -rf /usr/sbin/dnsmasq
  rm -rf /usr/share/man/man8/dnsmasq.8

  tar --overwrite -xvf "${dnsmasqFile}" -C /

  dnsmasq -v
fi
