#!/bin/sh
set -e

oneVer="${1:-0.7.0}"
twoVer="${2:-2.92}"
withLatest="${3:-0}"
dockerProject="sniproxy"
dockerBase="alpine:3.20"
dockerName="${dockerProject}_buildx"


manifest=""
for arch in "amd64" "arm64"; do
  docker run --rm --platform "linux/${arch}" "${dockerBase}" apk --print-arch >/dev/null 2>&1 || docker run --privileged --rm tonistiigi/binfmt --install "${arch}"
  docker rm -f "${dockerName}" >/dev/null 2>&1 || true
  docker run --platform "linux/${arch}" --name "${dockerName}" -id -v /mnt:/mnt "${dockerBase}"
  docker exec "${dockerName}" /bin/sh /mnt/commit.sh "${oneVer}" "${twoVer}"
  docker commit --change 'CMD ["/bin/sh", "/run.sh"]' "${dockerName}" "${dockerProject}_${arch}:${oneVer}"
  docker rm -f "${dockerName}" >/dev/null 2>&1 || true
  userName="$(docker info 2>/dev/null |grep 'Username:' |cut -d':' -f2 |sed 's/[[:space:]]//g')"
  [ -n "$userName" ] || continue
  [ "${withLatest}" = "1" ] && {
    docker tag "${dockerProject}_${arch}:${oneVer}" "${userName}/${dockerProject}_${arch}:latest"
    docker push "${userName}/${dockerProject}_${arch}:latest"
  }
  docker tag "${dockerProject}_${arch}:${oneVer}" "${userName}/${dockerProject}_${arch}:${oneVer}"
  docker push "${userName}/${dockerProject}_${arch}:${oneVer}"
  [ $? -eq 0 ] && manifest=`echo "--amend \"${userName}/${dockerProject}_${arch}:${oneVer}\" ${manifest}" |sed 's/\ \+$//'`
done

[ -n "$userName" ] && [ -n "$manifest" ] && eval `echo "docker manifest create \"${userName}/${dockerProject}:${oneVer}\" $manifest"` && docker manifest push -p "${userName}/${dockerProject}:${oneVer}"
[ -n "$userName" ] && [ -n "$manifest" ] && [ "${withLatest}" = "1" ] && eval `echo "docker manifest create \"${userName}/${dockerProject}:latest\" $manifest"` && docker manifest push -p "${userName}/${dockerProject}:latest"


# docker pull ocserv/ocserv:latest
# docker run --privileged --rm -it -p 443:443 ocserv/ocserv
# docker exec -it `docker ps -aq |head -n1` /bin/sh
# docker ps -aq |xargs docker rm -f
# docker images -aq |xargs docker rmi -f

