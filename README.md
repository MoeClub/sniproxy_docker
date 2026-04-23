# Run
```
docker run --restart always --name sniproxy -p 80:80/tcp -p 443:443/tcp -p 53:53/udp -e "PORT=53" -dt ocserv/sniproxy:latest

```

# Env
```
# 一般需要打开 80, 443, 53
# UDNS: 上游DNS地址(默认:8.8.4.4). -e "UPORT=8.8.4.4"
# UPORT: 上游DNS端口(默认:53). -e "UPORT=53"
# PORT: DNS服务的端口(本机对外提供的服务,默认:53). -e "PORT=53"
# ADDR: 本机IP地址(一般可自动识别)
# TABLE: sniporxy 配置中的 table 项. 以 ;; 间隔没一项. 以 ; 分割源地址和目标地址. -e "TABLE=*.abc.com;*:50443;;*.xyz.com;*.50443"

```

# Build
```
# apt install -y libarchive-tools
wget -qO- https://github.com/MoeClub/sniproxy_docker/archive/refs/heads/main.zip | bsdtar -xvf - --strip-components=1 -C /mnt
bash /mnt/buildx.sh 0.7.0 2.92

```
