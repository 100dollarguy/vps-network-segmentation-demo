#!/bin/bash

set -e

# 1. Create namespaces
ip netns add guestns
ip netns add iotns

# 2. Create veth pairs
ip link add veth-guest type veth peer name veth-guest-br
ip link add veth-iot type veth peer name veth-iot-br

# 3. Attach veths to namespaces
ip link set veth-guest netns guestns
ip link set veth-iot netns iotns

# 4. Create and bring up bridge
ip link add name br-vlan type bridge
ip link set br-vlan up

ip link set veth-guest-br master br-vlan
ip link set veth-iot-br master br-vlan
ip link set veth-guest-br up
ip link set veth-iot-br up

# 5. Assign IPs and bring up links
ip netns exec guestns ip addr add 10.10.10.2/24 dev veth-guest
ip netns exec iotns ip addr add 10.10.10.3/24 dev veth-iot
ip netns exec guestns ip link set veth-guest up
ip netns exec iotns ip link set veth-iot up

# 6. Set up iptables for one-way communication
ip netns exec guestns iptables -F
ip netns exec guestns iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip netns exec guestns iptables -A INPUT -s 10.10.10.3 -j DROP
ip netns exec iotns iptables -F

# 7. Add default routes as needed

# 8. Testing commands (run manually or put in a test script)
# From guestns: Should succeed
ip netns exec guestns ping -c 3 10.10.10.3
# From iotns: Should fail
ip netns exec iotns ping -c 3 10.10.10.2

# From primary (host): Test connectivity
ping -c 3 10.10.2.2
ping -c 3 10.10.3.2

echo "Setup Completed!"
