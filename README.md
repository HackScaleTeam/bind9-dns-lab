# BIND9 DNS Lab Bootstrap

A streamlined BIND9 deployment for `labnet.local` environments used in Sliver, Active Directory, and red team infrastructure labs.

This project automates the conversion of a fresh Ubuntu/Debian host into a reproducible internal DNS server with forward and reverse zones, recursive forwarding, query logging, and validation.

---

## Overview

The repository is designed for controlled lab environments where reliable DNS resolution is required for hosts such as:

* `target.labnet.local`
* `sliver.labnet.local`

The setup script automatically:

* installs BIND9 if missing
* detects the host IP and `/24` subnet
* renders forward and reverse zone templates
* updates AppArmor rules
* validates configuration integrity
* restarts and enables the service
* verifies resolution using `dig`

The result is a repeatable DNS layer suitable for offensive security simulations and infrastructure testing.

---

## Repository Layout

```text
bind9-dns-lab/
├── setup-bind9.sh
├── named.conf.options
├── named.conf.local
├── db.labnet.local
├── db.reverse.template
├── usr.sbin.named
└── README.md
```

---

## Installation

```bash
git clone <your-repository-url>
cd bind9-dns-lab
chmod +x setup-bind9.sh
./setup-bind9.sh
```

During execution, the script prompts for:

* `target.labnet.local` IP address
* `sliver.labnet.local` IP address

---

## Validation

After deployment, verify forward and reverse resolution.

```bash
dig @<DNS_IP> target.labnet.local +short
dig @<DNS_IP> sliver.labnet.local +short
dig -x <TARGET_IP> @<DNS_IP>
```

Successful output confirms both A and PTR records are operational.

---

## Use Cases

This repository is suitable for:

* Sliver transport labs
* Active Directory attack simulations
* malware analysis sandboxes
* red team infrastructure bootstrapping
* cyber range workshops

---

## Design Approach

The repository follows a practical infrastructure workflow:

> templated, validated, and fast to redeploy

The objective is to eliminate repetitive DNS setup tasks so effort can remain focused on:

* listeners
* implants
* pivot paths
* transport debugging
* OPSEC workflows

---

## Disclaimer

This repository is intended strictly for authorized lab, research, and educational environments.

---

## HackScale

Build the infrastructure once. Test it under failure. Rebuild it with precision.
