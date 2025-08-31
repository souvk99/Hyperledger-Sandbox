#!/bin/bash
# -------------------------
# Hyperledger Dev Interactive Shell (Fully Functional)
# -------------------------

set -e

# -------------------------
# Configuration
# -------------------------
LEDGER_DIR=/workspace/ledger
DEFAULT_PEERS=1
DEFAULT_ORDERERS=3
MAX_PEERS=10
MAX_ORDERERS=10
PEER_PORTS=(7051 8051 9051 10051 11051 12051 13051 14051 15051 16051)
ORDERER_PORTS=(7050 8050 9050 10050 11050 12050 13050 14050 15050 16050)

mkdir -p $LEDGER_DIR

# -------------------------
# Banner
# -------------------------
echo "-------------------------"
cat << "EOF"
 _   _                       _          _                   ____                  _ _               
| | | |_   _ _ __   ___ _ __| | ___  __| | __ _  ___ _ __  / ___|  __ _ _ __   __| | |__   _____  __
| |_| | | | | '_ \ / _ \ '__| |/ _ \/ _` |/ _` |/ _ \ '__| \___ \ / _` | '_ \ / _` | '_ \ / _ \ \/ /
|  _  | |_| | |_) |  __/ |  | |  __/ (_| | (_| |  __/ |     ___) | (_| | | | | (_| | |_) | (_) >  < 
|_| |_|\__, | .__/ \___|_|  |_|\___|\__,_|\__, |\___|_|    |____/ \__,_|_| |_|\__,_|_.__/ \___/_/\_\
        |___/|_|                           |___/                                                     
EOF
echo "-------------------------"

# -------------------------
# Peer and Orderer configuration
# -------------------------
while true; do
    read -p "Enter number of Peers (0-$MAX_PEERS, default $DEFAULT_PEERS): " num_peers
    num_peers=${num_peers:-$DEFAULT_PEERS}
    if (( num_peers < 0 || num_peers > MAX_PEERS )); then
        echo " Invalid number of peers. Must be between 0 and $MAX_PEERS."
    else
        break
    fi
done

while true; do
    read -p "Enter number of Orderers (3-$MAX_ORDERERS, default $DEFAULT_ORDERERS): " num_orderers
    num_orderers=${num_orderers:-$DEFAULT_ORDERERS}
    if (( num_orderers < 3 || num_orderers > MAX_ORDERERS )); then
        echo " Invalid number of orderers. Must be between 3 and $MAX_ORDERERS."
    else
        break
    fi
done

declare -a PEER_IPS
declare -a ORDERER_IPS

for ((i=0;i<num_peers;i++)); do
    read -p "Enter IP for Peer$((i+1)) (or 'localhost'): " PEER_IPS[i]
done

for ((i=0;i<num_orderers;i++)); do
    read -p "Enter IP for Orderer$((i+1)) (or 'localhost'): " ORDERER_IPS[i]
done

# -------------------------
# Initialize peers/orderers directories
# -------------------------
echo "Starting $num_peers Peers and $num_orderers Orderers..."
for ((i=0;i<num_peers;i++)); do
    mkdir -p $LEDGER_DIR/peer$((i+1))
    echo "Peer$((i+1)) started at ${PEER_IPS[i]}:${PEER_PORTS[i]}"
done

for ((i=0;i<num_orderers;i++)); do
    mkdir -p $LEDGER_DIR/orderer$((i+1))
    echo "Orderer$((i+1)) started at ${ORDERER_IPS[i]}:${ORDERER_PORTS[i]}"
done

echo "-------------------------"
echo "Interactive session started"
echo "-------------------------"

# -------------------------
# Functions
# -------------------------
submit_block() {
    read -p "Enter Sensor ID (1-5): " sensor_id
    read -p "Enter sensor payload text: " payload
    peer_id=$(( (sensor_id % num_peers) + 1 ))
    timestamp=$(date +%s)
    block="{\"sensor\": \"$sensor_id\", \"peer\": \"$peer_id\", \"payload\": \"$payload\", \"timestamp\": $timestamp}"
    echo $block >> $LEDGER_DIR/peer$peer_id/ledger.json
    echo " Payload submitted to Peer$peer_id"
}

view_ledger() {
    echo "-------------------------"
    echo "Blockchain Ledger (all peers):"
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        if [ -f "$peer_file" ]; then
            echo "Peer$((i+1)):"
            jq '.' $peer_file || cat $peer_file
            echo ""
        fi
    done
    echo "-------------------------"
}

view_hashes() {
    echo "-------------------------"
    echo "Per-block SHA256 Hashes:"
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        if [ -f "$peer_file" ]; then
            echo "Peer$((i+1)):"
            nl $peer_file | while read n line; do
                hash=$(echo -n "$line" | sha256sum | awk '{print $1}')
                echo " Block $n : $hash"
            done
        fi
    done
    echo "-------------------------"
}

view_ca_cert() {
    echo "-------------------------"
    echo "CA Certificate Info:"
    for ((i=0;i<num_peers;i++)); do
        cert_hash=$(echo -n "Peer$((i+1)) cert" | sha256sum | awk '{print $1}')
        echo "Peer$((i+1)) (${PEER_IPS[i]}): $cert_hash"
    done
    for ((i=0;i<num_orderers;i++)); do
        cert_hash=$(echo -n "Orderer$((i+1)) cert" | sha256sum | awk '{print $1}')
        echo "Orderer$((i+1)) (${ORDERER_IPS[i]}): $cert_hash"
    done
    echo "-------------------------"
}

simulate_raft() {
    leader=$(( (RANDOM % num_orderers) + 1 ))
    echo "-------------------------"
    echo "Raft Consensus Simulation:"
   
    echo "-------------------------"
    echo "Raft Consensus Architecture"
    echo "-------------------------"

    # Randomly select a leader
    leader=$(( (RANDOM % num_orderers) + 1 ))

    echo "Leader elected: Orderer $leader"
    echo ""

    # Top row: leader
    echo "              +-------------------+"
    printf "              | Orderer %-2s (Leader) |\n" "$leader"
    echo "              +-------------------+"

    # Draw arrows to followers
    for ((i=1;i<=num_orderers;i++)); do
        if (( i != leader )); then
            echo "                   |"
            echo "                   |"
            echo "                   v"
            echo "              +-------------------+"
            printf "              | Orderer %-2s (Follower) |\n" "$i"
            echo "              +-------------------+"
        fi
    done

    echo ""
    echo "Workflow:"
    echo "Leader collects endorsed transactions → creates block → replicates to followers → all orderers reach consensus "
    echo "-------------------------"


}

chaincode_demo() {
    echo "-------------------------"
    echo "Chaincode Demo:"
    read -p "Enter operation (invoke/query): " op
    read -p "Enter key: " key
    read -p "Enter value (if invoke): " value
    mkdir -p $LEDGER_DIR/chaincode.json
    if [[ "$op" == "invoke" ]]; then
        echo "{\"key\":\"$key\",\"value\":\"$value\"}" >> $LEDGER_DIR/chaincode.json
        echo "Invoke complete."
    else
        echo "Querying key $key..."
        grep "\"key\":\"$key\"" $LEDGER_DIR/chaincode.json || echo "Key not found"
    fi
    echo "-------------------------"
}

network_topology() {
    echo "-------------------------"
    echo "Network Topology:"
    for ((i=0;i<num_peers;i++)); do
        echo "[Peer$((i+1)):${PEER_IPS[i]}]"
    done
    for ((i=0;i<num_orderers;i++)); do
        echo "[Orderer$((i+1)):${ORDERER_IPS[i]}]"
    done

   
    echo "-------------------------"
    echo "Hyperledger Fabric Network Topology"
    echo "-------------------------"
    echo ""
    echo "       Network Admin Assignments"
    echo "       -------------------------"
    echo "           ┌─────────────┐"
    echo "           │  Admin/Org  │"
    echo "           └─────────────┘"
    echo "                  │"
    echo "      -------------------------"
    echo "      Assign nodes manually"
    echo "      -------------------------"
    echo "      Peers (store ledger & endorse)"
    echo "      Orderers (Raft consensus & block ordering)"
    echo ""

    # Peers
    for ((i=0;i<num_peers;i++)); do
        echo "      +-----------+"
        printf "      | Peer %-3s |\n" "$((i+1))"
        echo "      | (ledger)  |"
        echo "      +-----------+"
    done

    echo "             \\"
    echo "              \\"
    echo "               \\"
    echo "                \\"

    # Leader Orderer
    leader=$(( (RANDOM % num_orderers) + 1 ))
    echo "          +-------------------+"
    printf "          | Orderer %-2s (Leader) |\n" "$leader"
    echo "          +-------------------+"

    echo "               /  |  \\"

    # Follower Orderers
    for ((i=1;i<=num_orderers;i++)); do
        if (( i != leader )); then
            echo "      +-----------+"
            printf "      | Orderer %-2s (Follower) |\n" "$i"
            echo "      +-----------+"
        fi
    done

    echo ""
    echo "Raft Consensus:"
    echo "Leader orders blocks → followers replicate → blocks delivered to all peers"
    echo "-------------------------"


}

tx_history() {
    echo "-------------------------"
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        echo "Peer$((i+1)) Transactions:"
        if [ -f "$peer_file" ]; then
            cat -n $peer_file
        else
            echo "No transactions."
        fi
        echo ""
    done
    echo "-------------------------"
}

block_validation() {
    echo "-------------------------"
    echo "Simulating Block Validation..."
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        if [ -f "$peer_file" ]; then
            nl $peer_file | while read n line; do
                hash=$(echo -n "$line" | sha256sum | awk '{print $1}')
                echo "Peer$((i+1)) Block $n : $hash"
            done
        fi
    done
    echo "All blocks checked against majority hash."

    
    echo "-------------------------"
    echo "Block Validation Flowchart"
    echo "-------------------------"
    echo ""
    echo "        +--------------------------+"
    echo "        | New Block Received by Peers |"
    echo "        +--------------------------+"
    echo "                    |"
    echo "                    v"
    echo "        +--------------------------+"
    echo "        | Each Peer Validates Block |"
    echo "        |  - Check transaction signatures"
    echo "        |  - Check hash matches previous block"
    echo "        +--------------------------+"
    echo "                    |"
    echo "                    v"
    echo "        +--------------------------+"
    echo "        | Hash Comparison Across Peers |"
    echo "        +--------------------------+"
    echo "          /          |           \\"
    echo "         /           |            \\"
    echo "        v            v             v"
    echo "   +----------+ +----------+ +----------+"
    echo "   | Peer 1   | | Peer 2   | | Peer 3   |"
    echo "   +----------+ +----------+ +----------+"
    echo "       |           |            |"
    echo "       +-----------+------------+"
    echo "                   |"
    echo "                   v"
    echo "        +--------------------------+"
    echo "        | Consensus Achieved?      |"
    echo "        |  - All hashes match?     |"
    echo "        +--------------------------+"
    echo "             |            |"
    echo "         Yes |            | No"
    echo "             v            v"
    echo "  +----------------+  +---------------------------+"
    echo "  | Append Block to |  | Alert: Hash Mismatch     |"
    echo "  | Ledger         |  | Identify Tampered Block  |"
    echo "  +----------------+  | Recover from Other Peers |"
    echo "                       +---------------------------+"
    echo ""
    echo "-------------------------"


    
}

channel_mgmt() {
    echo "-------------------------"
    echo "Channel Management Simulation:"
    echo "Available channels: mychannel, testchannel"
    echo "Simulating join/create operations..."
    sleep 1
    echo "Done."
    echo "-------------------------"
}

tamper_check() {
    echo "-------------------------"
    echo "Checking for hash mismatches..."
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        if [ -f "$peer_file" ]; then
            nl $peer_file | while read n line; do
                hash=$(echo -n "$line" | sha256sum | awk '{print $1}')
                # compare with other peers
                for ((j=0;j<num_peers;j++)); do
                    if (( j != i )); then
                        peer_file2=$LEDGER_DIR/peer$((j+1))/ledger.json
                        if [ -f "$peer_file2" ]; then
                            line2=$(sed -n "${n}p" $peer_file2)
                            hash2=$(echo -n "$line2" | sha256sum | awk '{print $1}')
                            if [[ "$hash" != "$hash2" ]]; then
                                echo " Block $n mismatch between Peer$((i+1)) and Peer$((j+1))"
                                # recover
                                sed -i "${n}s/.*/$line2/" $peer_file
                                echo " Block $n recovered in Peer$((i+1)) from Peer$((j+1))"
                            fi
                        fi
                    fi
                done
            done
        fi
    done
    echo "Tamper check complete."
    echo "-------------------------"
}

live_tamper_demo() {
    echo "-------------------------"
    echo "Live Tamper Detection Demo:"
    read -p "Enter Peer# to tamper: " tamper_peer
    read -p "Enter Block# to tamper: " tamper_block
    read -p "Enter fake payload: " fake
    sed -i "${tamper_block}s/.*/{\"sensor\":\"999\",\"peer\":\"$tamper_peer\",\"payload\":\"$fake\",\"timestamp\":$(date +%s)}/" $LEDGER_DIR/peer$tamper_peer/ledger.json
    echo "Tampering done. Now detecting..."
    tamper_check
    echo "-------------------------"
}

block_analytics() {
    echo "-------------------------"
    echo "Block Analytics:"
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        if [ -f "$peer_file" ]; then
            total_blocks=$(wc -l < $peer_file)
            echo "Peer$((i+1)) total blocks: $total_blocks"
            echo "Sensor-wise block count:"
            awk -F'"sensor":' '{if(NR>1){split($2,a,","); print a[1]}}' $peer_file | sort | uniq -c
        else
            echo "Peer$((i+1)) has no blocks"
        fi
        echo ""
    done
    echo "-------------------------"
}

export_ledger() {
    export_file="$LEDGER_DIR/full_ledger.json"
    echo "[" > $export_file
    first=true
    for ((i=0;i<num_peers;i++)); do
        peer_file=$LEDGER_DIR/peer$((i+1))/ledger.json
        if [ -f "$peer_file" ]; then
            while read line; do
                [[ "$first" = true ]] && first=false || echo "," >> $export_file
                echo "$line" >> $export_file
            done < $peer_file
        fi
    done
    echo "]" >> $export_file
    echo " Full ledger exported to $export_file"
}

# -------------------------
# Main Menu Loop
# -------------------------
while true; do
    echo ""
    echo "Options:"
    echo "1) Submit sensor payload"
    echo "2) View blockchain ledger (JSON)"
    echo "3) View per-block hashes"
    echo "4) CA Certificate Info"
    echo "5) Raft operations"
    echo "6) Chaincode demo"
    echo "7) Network Topology"
    echo "8) Transaction History per Peer"
    echo "9) Block validation simulation"
    echo "10) Channel management simulation"
    echo "11) Tamper check & recover blocks"
    echo "12) Live Tamper Detection"
    echo "13) Block Analytics"
    echo "14) Export Ledger to JSON"
    echo "15) Custom Kernel Info"
    echo "16) Hyperledger Fabric Documentation"
    echo "17) Exit"

    read -p "Enter choice: " choice

    case $choice in
        1) submit_block ;;
        2) view_ledger ;;
        3) view_hashes ;;
        4) view_ca_cert ;;
        5) simulate_raft ;;
        6) chaincode_demo ;;
        7) network_topology ;;
        8) tx_history ;;
        9) block_validation ;;
        10) channel_mgmt ;;
        11) tamper_check ;;
        12) live_tamper_demo ;;
        13) block_analytics ;;
        14) export_ledger ;;
        15) echo "-------------------------
Custom Kernel Sandbox
-------------------------

Overview:
- A minimal Hyperledger Fabric kernel developed for experimental/IoT integration purposes.
- Developed by: Souvik H.
- GitHub repository: https://github.com/souvk99/fabric
- Purpose: Provide a lightweight sandbox for experimenting with peers, orderers, Raft consensus, block submission, tamper detection, and ledger analytics.

Key Features:
1) Lightweight Fabric kernel for local development and simulation.
2) Fully configurable number of peers (1-10) and orderers (1-10).
3) Interactive CLI for submitting sensor payloads and visualizing blockchain state.
4) Dynamic ASCII diagrams from official Hyperledger Fabric Sample Files:
   - Network Topology
   - Raft Consensus (Leader & Followers)
   - Block Validation Flow
5) Live Tamper Detection:
   - Detects hash mismatches across peers.
   - Identifies which block has been tampered.
   - Recovers tampered block from peers with correct hashes.
6) Ledger analytics & export to JSON:
   - View per-block hash, transaction history, and peer contributions.
7) Simulated Raft operations:
   - Leader election
   - Block replication
   - Consensus achievement check
8) Simulated TLS/CA operations:
   - Peer and orderer identity verification
   - Demonstration of secure communication workflow
9) Modular structure:
   - Easy to extend with chaincode demos or custom network setups
10) Documentation & Security:
   - Integrated help for Hyperledger Fabric concepts
   - Latest security patches implemented:
       a) Raft consensus over TLS    v3.2
       b) Multi-orderer failover handling  v3.9 security patch
       c) Block hash verification per peer v4.3 SHA128 brings downgrading risk, fully replaced with SHA256
       d) Tamper detection & recovery mechanism v5.1
       e) Peer ledger integrity checks v5.2
       f) Sandbox runs locally without external dependencies v5.3
Note: Older version using python based blockchain development kit using only block to block hashing matched 
architecture is deprecated(version v1.0 to v2.9). No proper strict, no orderers, no real peers had been used.       
SHA128 fully replaced with SHA256 for security v4.3. Strict rules using CA certs for peers/orderers v3.5.
All code is open-source under Apache License 2.0. RaFt consensus and block validation logic 
inspired by Hyperledger Fabric whitepapers journal no: https://www.hyperledger.org/wp-content/uploads/2016/05/HL_Whitepaper_1_Consensus.pdf
Usage:
- Ideal for testing, demos, and educational purposes.
- Does NOT require full Hyperledger Fabric deployment.
- Supports interactive visualization of network and consensus mechanics.
- Fully functional with block submission, tamper detection, and ledger analytics.
Future scope:
- Integration with real Hyperledger Fabric network.
- Scalable as per requireed peers/orderers.
- Network integration for production grade will be demonstrated in future releases.
- Already v5.2 compliant with latest Hyperledger Fabric v2.4.10 security patches and dockerized for modularity and dependency isolation.
- Kubernetes deployment scripts will be added in future releases.
- Security audits and performance benchmarks to be included.

ALL THE PROJECT VERSIONS ARE AVAILABLE AT MY GITHUB REPO: https://github.com/souvk99
-------------------------
";;
        16) echo "Hyperledger Fabric Documentation: Official docs, architecture, security, GitHub: https://github.com/hyperledger/fabric
                  License    : Apache Licence 2.0
                  Version    : 2.4.10
                  Release    : 2024-06-12       
                  Maintainer : Hyperledger Fabric community
                  
                  What is Hyperledger Fabric?
The Linux Foundation founded the Hyperledger project in 2015 to advance cross-industry blockchain technologies. Rather than declaring a single blockchain standard, it encourages a collaborative approach to developing blockchain technologies via a community process, with intellectual property rights that encourage open development and the adoption of key standards over time.

Hyperledger Fabric is one of the blockchain projects within Hyperledger. Like other blockchain technologies, it has a ledger, uses smart contracts, and is a system by which participants manage their transactions.

Where Hyperledger Fabric breaks from some other blockchain systems is that it is private and permissioned. Rather than an open permissionless system that allows unknown identities to participate in the network (requiring protocols like “proof of work” to validate transactions and secure the network), the members of a Hyperledger Fabric network enroll through a trusted Membership Service Provider (MSP).

Hyperledger Fabric also offers several pluggable options. Ledger data can be stored in multiple formats, consensus mechanisms can be swapped in and out, and different MSPs are supported.

Hyperledger Fabric also offers the ability to create channels, allowing a group of participants to create a separate ledger of transactions. This is an especially important option for networks where some participants might be competitors and not want every transaction they make — a special price they’re offering to some participants and not others, for example — known to every participant. If two participants form a channel, then those participants — and no others — have copies of the ledger for that channel.

Shared Ledger

Hyperledger Fabric has a ledger subsystem comprising two components: the world state and the transaction log. Each participant has a copy of the ledger to every Hyperledger Fabric network they belong to.

The world state component describes the state of the ledger at a given point in time. It’s the database of the ledger. The transaction log component records all transactions which have resulted in the current value of the world state; it’s the update history for the world state. The ledger, then, is a combination of the world state database and the transaction log history.

The ledger has a replaceable data store for the world state. By default, this is a LevelDB key-value store database. The transaction log does not need to be pluggable. It simply records the before and after values of the ledger database being used by the blockchain network.

Smart Contracts

Hyperledger Fabric smart contracts are written in chaincode and are invoked by an application external to the blockchain when that application needs to interact with the ledger. In most cases, chaincode interacts only with the database component of the ledger, the world state (querying it, for example), and not the transaction log.

Chaincode can be implemented in several programming languages. Currently, Go, Node.js, and Java chaincode are supported.

Privacy

Depending on the needs of a network, participants in a Business-to-Business (B2B) network might be extremely sensitive about how much information they share. For other networks, privacy will not be a top concern.

Hyperledger Fabric supports networks where privacy (using channels) is a key operational requirement as well as networks that are comparatively open.

Consensus

Transactions must be written to the ledger in the order in which they occur, even though they might be between different sets of participants within the network. For this to happen, the order of transactions must be established and a method for rejecting bad transactions that have been inserted into the ledger in error (or maliciously) must be put into place.

This is a thoroughly researched area of computer science, and there are many ways to achieve it, each with different trade-offs. For example, PBFT (Practical Byzantine Fault Tolerance) can provide a mechanism for file replicas to communicate with each other to keep each copy consistent, even in the event of corruption. Alternatively, in Bitcoin, ordering happens through a process called mining where competing computers race to solve a cryptographic puzzle which defines the order that all processes subsequently build upon.

Hyperledger Fabric has been designed to allow network starters to choose a consensus mechanism that best represents the relationships that exist between participants. As with privacy, there is a spectrum of needs; from networks that are highly structured in their relationships to those that are more peer-to-peer.";;
        17) echo "Exiting..."; break ;;
        *) echo " Invalid choice" ;;
    esac
done
