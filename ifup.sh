#! /bin/sh
. libs/net-vars.sh

echo "Executing '$0'"
sudo ip tuntap add dev $1 mode tap user $USER
sudo ip link set $1 promisc on
sudo ip link set $1 master $bridge
sudo ip link set $1 up
