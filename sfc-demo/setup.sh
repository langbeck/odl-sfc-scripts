#!/bin/bash
set -e

if [ -z "${http_proxy}" ]; then
    echo "http_proxy environment not defined"
    exit 1
fi

# Ensure https_proxy is equals to http_proxy and that are both exported
export http{,s}_proxy=${http_proxy}

# Disable sudo password requirement
sudo sed -i -r 's/^%sudo.*/%sudo ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Comment any existing apt proxy settings from default configuration file
test -e /etc/apt/apt.conf && sudo sed -i -r 's/^[^#](.*Proxy.*)/#\1/' /etc/apt/apt.conf

# We can't simply clone in home (setup_odl.sh does: rm -rf $HOME/sfc)
mkdir $HOME/git
cd $HOME/git

# Clone odl-sfc-scripts
git clone https://github.com/langbeck/odl-sfc-scripts.git
SCRIPTS_DIR=$PWD/odl-sfc-scripts/sfc-demo/

# Configure proxy environment files (docker, apt, profile, sudoers, etc)
sudo $SCRIPTS_DIR/setup_proxy.sh "${http_proxy}"

# Install docker
if ! which docker > /dev/null; then
    curl -L https://get.docker.com/ | sudo sh
    if ! which docker > /dev/null; then
        echo "ERRO: docker installation failed"
        exit 1
    fi
    sudo usermod -aG docker "${USER}"
fi

# Clone the sfc repository
git clone https://github.com/opendaylight/sfc.git
cd sfc

# Last commit tested and considered "stable"
git reset --hard f65065b19516a750b73262c63ba269fca2365e23

# Apply patches required to add proxy support
cp $SCRIPTS_DIR/*.patch ./
git apply *.patch

# Link base directories
test -d /sfc || sudo ln -s "${PWD}" /sfc
test -d /vagrant || sudo ln -s "/sfc/sfc-demo/sfc103" /vagrant

# Run the "original" setup_odl.sh
cd sfc-demo/sfc103
if ! ./setup_odl.sh; then
    echo "ERRO: ./setup_odl.sh exited with non-zero status code"
    exit 1
fi

# Ensure everything is "OK" in apt after ./setup_odl.sh
sudo apt install -f -y

if ! which java > /dev/null; then
    echo "ERRO: ./setup_odl.sh failed to install java (trying: apt install openjdk-8-jdk)"
    sudo apt install openjdk-8-jdk -y
fi

if ! which mvn > /dev/null; then
    echo "ERRO: ./setup_odl.sh failed to install maven (trying: apt install maven)"
    # package maven is version 3.3.3 in Ubuntu 15.10
    sudo apt install maven -y
fi

if [ ! -x $HOME/sfc/sfc-karaf/target/assembly/bin/karaf ]; then
    echo "ERRO: ./setup_odl.sh failed to setup karaf"
    exit 1
fi

if [ ! -d /vagrant/ovs-debs ] && [ -z "$(find /vagrant/ovs-debs -type f)" ]; then
    echo "ERRO: ./setup_odl.sh failed to build openvswitch .deb files"
    exit 1
fi

# Build in advance the sfc-service-node with the correct proxy configuration
cd /vagrant
sudo docker build --build-arg "http_proxy=${http_proxy}" . -t sfc-service-node || true
if [ -z "$(sudo docker images -q sfc-service-node)" ]; then
    echo "ERRO: pre-build of sfc-service-node failed"
    exit 1
fi
