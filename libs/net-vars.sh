bridge='br0'
bridge_addr='10.107.0.1'
bridge_mash='24'
bridge_dhcp_range_start='10.107.0.2'
bridge_dhcp_range_end='10.107.0.254'

default_routes=$(ip route ls | \
  awk '/^default / {
    for(i=0;i<NF;i++) { if ($i == "dev") { print $(i+1); next; } }
  }'
)
