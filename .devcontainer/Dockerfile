# DevContainer Dockerfile - Ubuntu 22.04 LTS
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/aws-cli/v2/current/bin:$PATH"

# Set versions for reproducibility
ARG NODE_VERSION=20.x
ARG DOTNET_VERSION=8.0
ARG AWSCLI_VERSION=2.15.30

# 1. Setup Repos & Install Base Tools
RUN mkdir -p /etc/apt/keyrings && \
    apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        sudo \
        unzip \
        software-properties-common \
        git \
        make \
        jq \
        vim \
        nano \
        iproute2 \
        iputils-ping && \
    \
    # NodeSource (Node.js LTS)
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION} jammy main" > /etc/apt/sources.list.d/nodesource.list && \
    \
    # Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    \
    # Microsoft (for dotnet & PowerShell)
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && rm -f /tmp/packages-microsoft-prod.deb && \
    \
    # Azure CLI
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/azurecli.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/azurecli.gpg] https://packages.microsoft.com/repos/azure-cli/ jammy main" > /etc/apt/sources.list.d/azure-cli.list && \
    \
    apt-get update && apt-get install -y --no-install-recommends \
        nodejs \
        dotnet-sdk-${DOTNET_VERSION} \
        powershell \
        docker-ce-cli \
        docker-compose-plugin \
        azure-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Install AWS CLI v2
RUN curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# 3. Install PowerShell OSD module
RUN pwsh -NoLogo -NoProfile -Command \
    "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module OSD -Scope AllUsers -Force -ErrorAction Stop"

# 4. Add non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# 5. Docker-in-Docker (DIND) support: add docker group
RUN groupadd docker || true && usermod -aG docker $USERNAME

USER $USERNAME
WORKDIR /workspace
