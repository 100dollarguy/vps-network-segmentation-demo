#!/bin/bash

# Delete namespaces (deletes veths inside)
ip netns del guestns
ip netns del iotns

# Delete bridge and veth-br if they still exist
ip link del br-vlan 2>/dev/null || true
ip link del veth-guest-br 2>/dev/null || true
ip link del veth-iot-br 2>/dev/null || true
