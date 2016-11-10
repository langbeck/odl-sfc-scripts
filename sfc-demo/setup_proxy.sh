#!/bin/bash
set -e

if [ $# -gt 1 ]; then
    echo "Usage $0 [http_proxy]"
    exit 1
fi


PROXY="$1"

# If a proxy wasn't provided, try to inherit the environment configuration.
if [ -z "${PROXY}" ]; then
    PROXY="${http_proxy}"

    if [ -z "${PROXY}" ]; then
        PROXY="${HTTP_PROXY}"
    fi
fi



config_file() {
    rm -f "$1" && test -n "${PROXY}" && mkdir -p "$(dirname $1)" && tee > $1 || true
}


config_file /etc/systemd/system/docker.service.d/proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=${PROXY}"
EOF

config_file /etc/apt/apt.conf.d/99proxy <<EOF
Acquire::https::Proxy "${PROXY}";
Acquire::http::Proxy "${PROXY}";
EOF

config_file /etc/profile.d/proxy.sh <<EOF
export http{,s}_proxy=${PROXY}
EOF

config_file /etc/sudoers.d/proxy <<EOF
Defaults env_keep += "http_proxy"
Defaults env_keep += "https_proxy"
Defaults env_keep += "HTTP_PROXY"
Defaults env_keep += "HTTPS_PROXY"
EOF
