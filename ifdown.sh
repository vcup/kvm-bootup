#! /bin/sh
. libs/net-vars.sh

echo "Executing $0"
sudo /usr/bin/ip link set $1 down
sudo /usr/bin/ip link delete dev $1
