# Hyperledger Sandbox – Custom Kernel
Developed by : Souvik H
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)  
**GitHub Repository**: [https://github.com/souvk99/fabric](https://github.com/souvk99/fabric)

---
##
  _   _                       _          _                   ____                  _ _               
 | | | |_   _ _ __   ___ _ __| | ___  __| | __ _  ___ _ __  / ___|  __ _ _ __   __| | |__   _____  __
 | |_| | | | | '_ \ / _ \ '__| |/ _ \/ _` |/ _` |/ _ \ '__| \___ \ / _` | '_ \ / _` | '_ \ / _ \ \/ /
 |  _  | |_| | |_) |  __/ |  | |  __/ (_| | (_| |  __/ |     ___) | (_| | | | | (_| | |_) | (_) >  < 
 |_| |_|\__, | .__/ \___|_|  |_|\___|\__,_|\__, |\___|_|    |____/ \__,_|_| |_|\__,_|_.__/ \___/_/\_\
        |___/|_|                           |___/                                                     

## Overview

**Hyperledger Sandbox** is a **custom interactive development environment** built on top of **Hyperledger Fabric 2.5.7**, designed to simulate a blockchain network for sensor payloads.  
This sandbox provides **immutable storage, block validation, Raft consensus simulation, tamper detection, and advanced network visualization** — all in a **self-contained Docker container**.

The project is developed by **Souvik H.** as a **custom kernel over the official Hyperledger Fabric framework**.

---

## Features

- **Dynamic Peer & Orderer Configuration**  
  - Define 1–10 peers and 1–10 orderers.  
  - Assign IPs (localhost or physical network) dynamically.  
  - Minimum 3 orderers enforced for Raft consensus.

- **Sensor Payload Simulation**  
  - Submit sensor data to multiple peers.  
  - Automatic timestamping and block creation.  

- **Raft Consensus Simulation**  
  - Leader election, log replication, and block ordering.  
  - Visual ASCII diagrams to simulate Raft behavior.  

- **Tamper Detection**  
  - “Live Tamper Detection” mode highlights hash mismatches if any block is altered manually.  
  - Option to recover mismatched blocks from peers with valid hashes.

- **Ledger Management**  
  - View blockchain ledger per peer.  
  - Export ledger to JSON format.  
  - Block hash generation and verification.

- **Chaincode & Network Simulation**  
  - Simulate chaincode invoke & query.  
  - Create/join channels (simulated).  
  - Network topology visualization (ASCII diagram).

- **Security Mechanisms**  
  - TLS encryption simulation.  
  - CA certificate info for identity management.  
  - Hash validation for all blocks.  

- **Documentation & References**  
  - Integrated **Hyperledger Fabric documentation summary**.  
  - Custom kernel documentation and GitHub repo link.  

---

## Custom Kernel Updates (Highlights)

1. Implemented **Raft consensus** with leader election simulation.  
2. Commissioned **Raft over TLS** for secure transaction ordering.  
3. Added **live tamper detection** for block integrity validation.  
4. Multi-peer and multi-orderer network simulation.  
5. Block hash computation for every transaction.  
6. Ledger export and per-block analytics for debugging and demonstration.

---

## Requirements

- Docker (tested on Docker Desktop / Linux)
- Internet connection (for building the image only)
- Minimal system resources: 2 CPU cores, 4 GB RAM recommended

---

## Getting Started

1. **Clone Repository**

```bash
git clone https://github.com/souvk99/fabric.git
cd fabric
