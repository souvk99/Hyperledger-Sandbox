FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Core dependencies
RUN apt-get update && apt-get install -y \
    curl wget git unzip build-essential \
    python3 python3-pip python3-venv \
    openjdk-17-jdk \
    ruby-full \
    rustc cargo \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Node.js + npm + yarn (pinned)
# -----------------------------
# Node 18.x (Hyperledger Fabric compatible)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    npm install -g npm@10.8.2 yarn@1.22.22

# -----------------------------
# Go (Fabric chaincode toolchain)
# -----------------------------
ENV GO_VERSION=1.21.13
RUN curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# -----------------------------
# Hyperledger Fabric tools
# -----------------------------
ENV FABRIC_VERSION=2.5.7
ENV FABRIC_CA_VERSION=1.5.11
RUN curl -sSL https://github.com/hyperledger/fabric/releases/download/v${FABRIC_VERSION}/hyperledger-fabric-linux-amd64-${FABRIC_VERSION}.tar.gz \
    | tar -xz -C /usr/local/bin --strip-components=1 && \
    curl -sSL https://github.com/hyperledger/fabric-ca/releases/download/v${FABRIC_CA_VERSION}/hyperledger-fabric-ca-linux-amd64-${FABRIC_CA_VERSION}.tar.gz \
    | tar -xz -C /usr/local/bin --strip-components=1

#FABRIC SAMPLES
# -----------------------------
# Fabric Samples (baked inside)
# -----------------------------
ENV FABRIC_SAMPLES=/opt/fabric-samples
RUN git clone https://github.com/hyperledger/fabric-samples.git $FABRIC_SAMPLES
# -----------------------------
# Set up Python, Ruby, Rust
# -----------------------------
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel flask
RUN gem install bundler rake

# Rust installed earlier with apt
# Validate toolchain
RUN go version && node -v && npm -v && yarn -v && python3 --version && pip --version && ruby -v && rustc --version
# -----------------------------
# Add interactive shell script
# -----------------------------
COPY hyperledger-shell.sh /usr/local/bin/hyperledger-shell.sh
RUN chmod +x /usr/local/bin/hyperledger-shell.sh

WORKDIR /workspace
CMD ["/usr/local/bin/hyperledger-shell.sh"]
