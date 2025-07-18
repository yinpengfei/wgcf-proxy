# amd64
docker build -f Dockerfile --no-cache --progress=plain -t yinpengfei/wgcf-proxy --platform linux/amd64 .

# arm64 
docker build -f Dockerfile --no-cache --progress=plain -t yinpengfei/wgcf-proxy:arm64 --platform linux/arm64 .

# 打包同时支持amd64和arm64
docker buildx build --platform linux/amd64,linux/arm64 -t yinpengfei/wgcf-proxy -f Dockerfile --push .


docker run --rm -it \
    --name wgcf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --privileged --cap-add net_admin \
    -v /lib/modules:/lib/modules \
    -v $(pwd)/wgcf:/wgcf \
    -p 1080:1080 \
    yinpengfei/wgcf-proxy -6

docker run --rm -it \
    --name wgcf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --privileged --cap-add net_admin \
    -v /lib/modules:/lib/modules \
    -v $(pwd)/wgcf:/wgcf \
    yinpengfei/wgcf-docker  sh
