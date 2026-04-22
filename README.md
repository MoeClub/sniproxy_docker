# Build
```
# apt install -y libarchive-tools
wget -qO- https://github.com/MoeClub/sniproxy_docker/archive/refs/heads/main.zip | bsdtar -xvf - --strip-components=1 -C /mnt
bash /mnt/buildx.sh 0.7.0 2.92

```
