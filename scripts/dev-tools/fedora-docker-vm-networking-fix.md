# 🧠 Fixing Docker vs Virt-Manager Networking Conflict on Fedora

## 🐧 TL;DR

If you installed Docker _after_ virt-manager/QEMU, your VMs might lose internet access. Docker rewrites firewall rules (`iptables`) that block libvirt’s virtual bridge (`virbr0`). This guide shows how to patch that safely so **both Docker containers and VMs can access the internet**.

---

## 🧩 What Happened?

1. ✅ You installed **virt-manager/QEMU** first → VMs worked fine.
2. 🐳 You installed **Docker Engine** (not Docker Desktop) → Docker works, but VMs lost internet.
3. 🧱 Docker modified `iptables` rules → broke forwarding between `virbr0` and your real network interface (`wlp2s0`).

---

## 🔍 Diagnosing the Problem

Run this to list all bridges:

```bash
ip link show type bridge
```

You’ll likely see:

- `docker0` → Docker’s default bridge
- `virbr0` → libvirt’s NAT bridge for VMs

---

## ✅ Quick Fix: Patch `iptables` Rules

Run these commands to restore VM internet access:

```bash
sudo iptables -I FORWARD -i virbr0 -o wlp2s0 -j ACCEPT
sudo iptables -I FORWARD -i wlp2s0 -o virbr0 -j ACCEPT
```

> Replace `wlp2s0` with your actual outbound interface if different (check with `ip a`).

---

## 🧠 What These Commands Do

- `-i virbr0 -o wlp2s0` → allows VMs to send packets out to the internet
- `-i wlp2s0 -o virbr0` → allows replies from the internet to reach your VMs

Without these, Docker’s firewall rules block VM traffic.

---

## ⚠️ DO NOT MAKE IT PERSISTENT

It **will** break Docker's internet access.

<!--
## 🔁 Make It Persistent (Optional but Recommended)

### Option 1: Save with `iptables-services`

```bash
sudo dnf install iptables-services
sudo systemctl enable iptables
sudo service iptables save
```

### Option 2: Use a systemd service

Create a script:

```bash
sudo nano /usr/local/bin/patch-qemu-network.sh
```

Paste this:

```bash
#!/bin/bash
iptables -C FORWARD -i virbr0 -o wlp2s0 -j ACCEPT || iptables -I FORWARD -i virbr0 -o wlp2s0 -j ACCEPT
iptables -C FORWARD -i wlp2s0 -o virbr0 -j ACCEPT || iptables -I FORWARD -i wlp2s0 -o virbr0 -j ACCEPT
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/patch-qemu-network.sh
```

Create a systemd unit:

```bash
sudo nano /etc/systemd/system/qemu-netfix.service
```

Paste this:

```ini
[Unit]
Description=Patch iptables for QEMU networking
After=network.target docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/patch-qemu-network.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo systemctl enable qemu-netfix.service
```

--- -->

## 🧼 Bonus: Check Your Interfaces

```bash
ip a
```

Look for:

- `virbr0` → VM bridge
- `wlp2s0` → Wi-Fi (or `enpX` for Ethernet)

---

## 🧠 Why Not Use `"bridge": "virbr0"` in Docker?

Because `virbr0` is managed by **libvirt**, not Docker. Docker expects full control over its bridge. Pointing Docker to `virbr0` can break VM networking or cause Docker to fail.

---

## 🧪 Verified Working Setup

| Component  | Bridge Used | Internet Access | Notes                     |
| ---------- | ----------- | --------------- | ------------------------- |
| Docker     | `docker0`   | ✅              | Default setup             |
| QEMU VMs   | `virbr0`    | ✅              | After patching `iptables` |
| Host Wi-Fi | `wlp2s0`    | ✅              | Shared outbound interface |

---

<details>
<summary>📚 References & Credits</summary>

This guide was inspired by insights from the [Arch Wiki’s Docker networking section](https://wiki.archlinux.org/title/Docker#Starting_Docker_breaks_KVM_bridged_networking), which documents how Docker’s iptables rules can interfere with KVM bridged networking. Huge thanks to the Arch community for maintaining such a detailed and helpful resource.

</details>
