# Simple Segmented Networks on a Single Server

## 1. What Is This Project About?
This project shows how you can create a mini, segmented network—like you’d find in a company—using just one Linux server. It uses “network namespaces,” so you can simulate different devices or subnets (like a main PC, a guest device, and an IoT gadget) without buying more hardware or cloud servers.

## 2. Why Did I Do It?
I wanted to practice real-world network security and segmentation in a low-cost way, without renting lots of machines. I wanted to know if you could build and test proper firewall rules—just like a network engineer—in a safe, single-server environment.

## 3. What Did I Want to Achieve?
- Simulate 3 “zones”: **primary**, **guest**, **iot**.
- Let primary talk to everyone, guest talk to iot, and **block iot from talking to anyone else**.
- Make it as close as possible to a real network, so I could test, troubleshoot, and truly understand segmentation.

## Network Segmentation Policy
| Source    | Destination      | Allowed?   | Method              | Comment                       |
|-----------|-----------------|------------|---------------------|-------------------------------|
| Primary   | Guest           | YES        | Direct veth         | Full access                   |
| Primary   | IoT             | YES        | Direct veth         | Full access                   |
| Guest     | IoT             | YES        | Bridge (br-vlan)    | Allowed, initiates to IoT     |
| IoT       | Guest           | NO         | Bridge (br-vlan)    | Blocked by iptables           |
| Guest     | Primary         | NO         | -                   | Network unreachable           |
| IoT       | Primary         | NO         | -                   | Network unreachable           |


## 4. Tools Used
- **Linux network namespaces**: To make each “zone” feel like its own device.
- **Bridges and veth pairs**: To connect the namespaces as you’d connect real hardware.
- **UFW and iptables**: To make firewall rules and control who can talk to whom.
- **Ping, netcat, arping**: To test if traffic is really allowed or blocked.
- **Bash scripts**: To automate setup and cleanup.
- *(Optionally) Drawing tools*: For network diagrams.

## 5. Problems I Faced
- At first, **all my “devices” could still talk freely**—the firewall wasn’t working as I expected on a single server.
- Local Linux interfaces sometimes **bypass normal firewall rules**—I had to learn about “forwarded” and “local” traffic.
- **Routing and ARP confusion**: If you don’t clean up or reset IP addresses/veths, things just don’t work.

## 6. How Did I Overcome It?
- Used **network namespaces** to simulate true physical separation.
- Made a **Linux bridge** to join guest and IoT as if on the same switch, but used iptables for one-way trust.
- Cleaned and re-set each setup step (reset IPs, flush routes), and tested layer by layer (ARP, ping, then firewall).
- Used **stateful iptables rules** (`ESTABLISHED,RELATED`) so replies to allowed requests worked—but new connections from blocked zones didn’t.

## 7. What Did I Learn?
- You can create **realistic, secure, segmented networks** using just one VPS and free Linux features.
- **Firewall testing is tricky** if you don’t understand how Linux routes internal vs. external traffic.
- Documenting every step and testing with simple tools (ping/arping/netcat) makes troubleshooting manageable.
- **Network security is as much about testing and verification as it is about writing the rules!**

## 8. Screenshots & Network Diagrams

### **Project Architecture Diagram**

![Network Architecture](/screenshots/architecture.png)

---

### **Successful Guest to IoT Ping**

*(Guest can talk to IoT — allowed)*
![Guest to IoT ping success](/screenshots/guest%20to%20iot.png)

---

### **IoT to Guest Blocked**

*(IoT cannot talk to Guest — denied, as per firewall rules)*
![IoT to Guest blocked](/screenshots/iot%20to%20guest.png)

---

### **iptables Rules for Guest**

*(Firewall setup in guest namespace)*
![Guest iptables input chain](/screenshots/firewall%20rules%20in%20guest%20namespace.png)

---

### **Primary to Guest/IoT - Allowed**

*(Host/Primary can reach both Guest and IoT)*
![Primary to Guest and IoT success](/screenshots/primary%20to%20guest.png)

![Primary to Guest and IoT success](/screenshots/primary%20to%20iot.png)

9. How to Run or Test (Quick Start)

Clone the repo and run the setup script:

```bash
git clone https://github.com/100dollarguy/vps-network-segmentation-demo.git
```

```bash
./setup/network_setup.sh
```
For cleanup, use:

```bash
./teardown/network_cleanup.sh
```
Or, to test manually, use these commands one by one:

1. Test: Primary (host) to Guest (direct veth)

```bash
ping -c 3 10.10.2.2      # Should SUCCEED
```
2. Test: Primary (host) to IoT (direct veth)

```bash
ping -c 3 10.10.3.2      # Should SUCCEED
```
3. Test: Guest to IoT (over the bridge)

```bash
sudo ip netns exec guestns ping -c 3 10.10.10.3    # Should 
SUCCEED
```
4. Test: IoT to Guest (over the bridge)

```bash
sudo ip netns exec iotns ping -c 3 10.10.10.2      # Should FAIL (blocked by firewall)
```
5. Test: Guest to Primary
(Should NOT be allowed if segmentation enforced)

```bash
sudo ip netns exec guestns ping -c 3 10.10.1.2     # Should FAIL (network unreachable or timeout)
```
6. Test: IoT to Primary
(Should NOT be allowed if segmentation enforced)

```bash
sudo ip netns exec iotns ping -c 3 10.10.1.2       # Should FAIL (network unreachable or timeout)
```
7. Show firewall rules in guest namespace (for troubleshooting)

```bash
sudo ip netns exec guestns iptables -L INPUT -v -n
```

## ✨ License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This project is licensed under the [MIT License](LICENSE).
You're free to use, modify, and share it — personally or commercially.

Feel free to fork it, improve it for your own setup, or share with others!
