#!/bin/sh

# [ ! -e "/dev/net/tun" ] && echo "try with --privileged " && exit 1
device=`ls -1 /sys/class/net| grep -v '^lo$' |head -n 1`
[ -n "$device" ] || exit 1
addr=`wget -qO- https://checkip.amazonaws.com/`
[ -n "$addr" ] || addr=`ip -4 addr show "$net" | awk '/inet /{print $2}' | cut -d/ -f1`
[ -n "$addr" ] && echo "Addr: ${addr}"

echo `printenv TABLE`

