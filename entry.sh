#!/bin/sh
set -e

_downwgcf() {
  echo
  echo "clean up"
  if ! wg-quick down wgcf; then
    echo "error down"
  fi
  echo "clean up done"
  exit 0
}

runwgcf() {
  trap '_downwgcf' ERR TERM INT

  _enableV4="1"
  if [ "$1" = "-6" ]; then
    _enableV4=""
  fi

  if [ ! -e "wgcf-account.toml" ]; then
    wgcf register --accept-tos
  fi

  if [ ! -e "wgcf-profile.conf" ]; then
    wgcf generate
  fi

  cp wgcf-profile.conf /etc/wireguard/wgcf.conf

  DEFAULT_GATEWAY_NETWORK_CARD_NAME=`route  | grep default  | awk '{print $8}' | head -1`
  DEFAULT_ROUTE_IP=`ifconfig $DEFAULT_GATEWAY_NETWORK_CARD_NAME | grep "inet " | awk '{print $2}' | sed "s/addr://"`

  echo ${DEFAULT_GATEWAY_NETWORK_CARD_NAME}
  echo ${DEFAULT_ROUTE_IP}

  sed -i "/\[Interface\]/a PostDown = ip rule delete from $DEFAULT_ROUTE_IP  lookup main" /etc/wireguard/wgcf.conf
  sed -i "/\[Interface\]/a PostUp = ip rule add from $DEFAULT_ROUTE_IP lookup main" /etc/wireguard/wgcf.conf

  if [ "$1" = "-6" ]; then
    sed -i 's/AllowedIPs = 0.0.0.0/#AllowedIPs = 0.0.0.0/' /etc/wireguard/wgcf.conf
  elif [ "$1" = "-4" ]; then
    sed -i 's/AllowedIPs = ::/#AllowedIPs = ::/' /etc/wireguard/wgcf.conf
  fi

  modprobe iptable_raw
  modprobe ip6table_raw

  wg-quick up wgcf

  if [ "$_enableV4" ]; then
    _checkV4
  else
    _checkV6
  fi

  echo
  echo "OK, wgcf is up."
  _startBrookProxy

  sleep infinity & wait
}

_checkV4() {
  echo "Checking network status, please wait...."
  while ! curl --max-time 2 ipinfo.io; do
    wg-quick down wgcf
    echo "Sleep 2 and retry again."
    sleep 2
    wg-quick up wgcf
  done
}

_checkV6() {
  echo "Checking network status, please wait...."
  while ! curl --max-time 2 -6 ipv6.google.com; do
    wg-quick down wgcf
    echo "Sleep 2 and retry again."
    sleep 2
    wg-quick up wgcf
  done
}

_startBrookProxy() {
  echo "starting brook proxy server (HTTP+SOCKS5, 多协议混合端口)..."
  # 读取环境变量，支持自定义端口/密码
  BROOK_PORT="${PORT:-1080}"
  BROOK_ADDR="${HOST:-0.0.0.0}"
  BROOK_PASS="${PASSWORD:-123456}"

  # Brook 不需要区分 HTTP/SOCKS5，自动判别，支持同一端口多协议
  /usr/local/bin/brook server -l "${BROOK_ADDR}:${BROOK_PORT}" -p "${BROOK_PASS}" &
  echo "brook proxy server is running on ${BROOK_ADDR}:${BROOK_PORT} (password: ${BROOK_PASS})"
}

if [ -z "$@" ] || [[ "$1" = -* ]]; then
  runwgcf "$@"
else
  exec "$@"
fi

