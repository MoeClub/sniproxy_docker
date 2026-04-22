#!/bin/sh
set -e

ocVer="${1:-1.4.2}"
dnsVer="${2:-2.92}"
withLatest="${3:-0}"
dockerBase="alpine:3.20"
dockerName="ocserv_buildx"

manifest=""
for arch in "amd64" "arm64"; do
  docker run --privileged --rm tonistiigi/binfmt --install "${arch}"
  docker rm -f "${dockerName}" >/dev/null 2>&1 || true
  docker run --platform "linux/${arch}" --name "${dockerName}" -id -v /mnt:/mnt "${dockerBase}"
  docker exec "${dockerName}" /bin/sh /mnt/commit.sh "${ocVer}" "${dnsVer}"
  docker commit --change 'CMD ["/bin/sh", "/run.sh"]' "${dockerName}" "${arch}:${ocVer}"
  docker rm -f "${dockerName}" >/dev/null 2>&1 || true
  userName="$(docker info 2>/dev/null |grep 'Username:' |cut -d':' -f2 |sed 's/[[:space:]]//g')"
  [ -n "$userName" ] || continue
  [ "${withLatest}" = "1" ] && {
    docker tag "${arch}:${ocVer}" "${userName}/${arch}:latest"
    docker push "${userName}/${arch}:latest"
  }
  docker tag "${arch}:${ocVer}" "${userName}/${arch}:${ocVer}"
  docker push "${userName}/${arch}:${ocVer}"
  [ $? -eq 0 ] && manifest=`echo "--amend \"${userName}/${arch}:${ocVer}\" ${manifest}" |sed 's/\ \+$//'`
done

[ -n "$manifest" ] && eval `echo "docker manifest create \"${userName}/ocserv:${ocVer}\" $manifest"` && docker manifest push -p "${userName}/ocserv:${ocVer}"
[ -n "$manifest" ] && [ "${withLatest}" = "1" ] && eval `echo "docker manifest create \"${userName}/ocserv:latest\" $manifest"` && docker manifest push -p "${userName}/ocserv:latest"


# docker pull ocserv/ocserv:latest
# docker run --privileged --rm -it -p 443:443 ocserv/ocserv
# docker exec -it `docker ps -aq |head -n1` /bin/sh
# docker ps -aq |xargs docker rm -f
# docker images -aq |xargs docker rmi -f

