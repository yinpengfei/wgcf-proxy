FROM alpine:3.17 AS builder

RUN apk update -f \  
  && apk --no-cache add -f \  
  git gcc musl-dev make

RUN curl -L -o /usr/local/bin/brook \
      https://github.com/txthinking/brook/releases/download/v${BROOK_VERSION}/brook_linux_amd64 \
    && chmod +x /usr/local/bin/brook


# 阶段 2：创建最终镜像
FROM alpine:3.17

RUN apk update -f \  
  && apk --no-cache add -f \  
  curl ca-certificates \  
  iproute2 net-tools iptables \  
  wireguard-tools openresolv \  
  && rm -rf /var/cache/apk/*  

RUN curl -fsSL git.io/wgcf.sh | bash && mkdir -p /wgcf  

WORKDIR /wgcf  

VOLUME /wgcf  

COPY entry.sh /entry.sh  
RUN chmod +x /entry.sh  

ENTRYPOINT ["/entry.sh"]
